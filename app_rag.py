import os
import pickle
import faiss
import gradio as gr
import numpy as np
from pathlib import Path
from sentence_transformers import SentenceTransformer
from PyPDF2 import PdfReader
from datetime import datetime
import time
import ollama
import logging
import threading
import re

# ---------------- CONFIG ----------------
MODEL_NAME = "llama3.2:3b"      # Ollama model name
TOP_K = 3                  # number of docs to retrieve
CHUNK_SIZE = 1000          # chars per chunk
INDEX_FILE = "faiss_store_author.pkl"
history_file = "app_history.txt"

#embedder = SentenceTransformer("all-MiniLM-L6-v2")
embedder = SentenceTransformer("sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")

faiss_store = None
counter_lock = threading.Lock()
# ---------------- Logging ----------------
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
# ---------------- Document Loading ----------------
# ---------------- HELPERS ----------------
def extract_text(file_path):
    """Extract text from PDF or TXT, robustly."""
    if file_path.endswith(".txt"):
        try:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                return f.read()
        except Exception as e:
            print(f"⚠️ Skipping TXT {file_path}: {e}")
            return ""
    elif file_path.endswith(".pdf"):
        try:
            reader = PdfReader(file_path)
            text = ""
            for page in reader.pages:
                t = page.extract_text()
                if t:
                    text += t
            return text
        except Exception as e:
            print(f"⚠️ Skipping PDF {file_path}: {e}")
            return ""
    return ""

# ---------------- BUILD FAISS ----------------
def build_faiss_index(folder_path, output_file=INDEX_FILE):
    t0 = time.time()
    documents = []
    metadata_list = []

    for root, _, files in os.walk(folder_path):
        for file in files:
            if file.endswith(".txt") or file.endswith(".pdf"):
                file_path = os.path.join(root, file)
                text = extract_text(file_path)
                if not text.strip():
                    continue  # skip empty or failed files

                # Infer author/book from folder structure: /Author/Book/file
                parts = Path(file_path).parts
                author = parts[-2] if len(parts) >= 3 else "Unknown"
                book = parts[-1] if len(parts) >= 2 else "Unknown"
                logging.info(f"Loading Author {author} Book {book}  ")
                chunks = [text[i:i+CHUNK_SIZE] for i in range(0, len(text), CHUNK_SIZE)]
                documents.extend(chunks)
                metadata_list.extend([{"author": author, "book": book, "file": file}] * len(chunks))

    logging.info(f"Document loading took {time.time() - t0:.2f} sec")
    if not documents:
        raise ValueError("No valid .txt or .pdf documents found in the folder.")

    t1 = time.time()
    embeddings = embedder.encode(documents, convert_to_numpy=True).astype(np.float32)
    logging.info(f"Embedding took {time.time() - t1:.2f} sec")
    dim = embeddings.shape[1]
    index = faiss.IndexFlatL2(dim)
    index.add(embeddings)
    logging.info(f"Indexing took {time.time() - t1:.2f} sec (including embedding)")

    with open(output_file, "wb") as f:
        pickle.dump((index, documents, metadata_list), f)

    logging.info(f"Total build_faiss_index time: {time.time() - t0:.2f} sec")
    print(f"✅ FAISS index built and saved to {output_file}")
    return index, documents, metadata_list

def load_faiss_index(file=INDEX_FILE):
    if not os.path.exists(file):
        raise FileNotFoundError("FAISS index not found. Build it first.")
    with open(file, "rb") as f:
        index, docs, metadata = pickle.load(f)
    return index, docs, metadata

def get_authors(metadata):
    return sorted(list(set(m["author"] for m in metadata)))

def get_last_counter():
    try:
        with open(history_file, "r", encoding="utf-8") as f:
            lines = f.readlines()
        for line in reversed(lines):
            match = re.match(r"Q(\d+):", line)
            if match:
                return int(match.group(1))
    except FileNotFoundError:
        pass
    return 0

question_counter = get_last_counter()

def log_history(question, answer):
    global question_counter

    with counter_lock:
        question_counter += 1
        with open(history_file, "a", encoding="utf-8") as f:
            f.write(f"Q{question_counter}: {question}\nA{question_counter}: {answer} Date of Question {datetime.now()}\n---\n")

# ---------------- QUERY ----------------
def query_rag_stream(question, author):
    global faiss_store, question_counter
    index, docs, metadata = faiss_store
    chat_pairs = []

    logging.info(f"Question {question} Received for Author {author}")

    start_time = time.time()
    # Filter by author
    if author != "All":
        filtered_indices = [i for i, m in enumerate(metadata) if m["author"].lower() == author.lower()]
        if not filtered_indices:
            answer = f"No documents found for author '{author}'."
            chat_pairs.append((question, answer))
            log_history(question, answer)
            yield chat_pairs
            return
    else:
        filtered_indices = list(range(len(docs)))

    logging.info(f"Author filtering took {time.time() - start_time:.2f} sec")

    # Embed query
    t_embed = time.time()
    q_emb = embedder.encode([question], convert_to_numpy=True).astype(np.float32)
    logging.info(f"Query embedding took {time.time() - t_embed:.2f} sec")

    # Search only top N candidates for speed
    N_CANDIDATES = min(100, len(docs))
    t_search = time.time()
    D, I = index.search(q_emb, N_CANDIDATES)
    logging.info(f"FAISS search (top {N_CANDIDATES}) took {time.time() - t_search:.2f} sec")

    # Keep only filtered results
    I_filtered = [i for i in I[0] if i in filtered_indices][:TOP_K]
    retrieved = [(docs[i], metadata[i]) for i in I_filtered]

    if not retrieved:
        answer = f"No relevant documents found for author '{author}'."
        chat_pairs.append((question, answer))
        log_history(question, answer)
        yield chat_pairs
        return

    # Build context
    t_context = time.time()
    context = "\n\n---\n\n".join(
        f"[{m['author']} - {m['book']}]: {d[:CHUNK_SIZE]}" for d, m in retrieved
    )
    logging.info(f"Context building took {time.time() - t_context:.2f} sec")
    user_prompt = f"""
You are a wise and compassionate spiritual guide.
Your role is to answer the user’s question based on the provided context from sacred or philosophical texts.

Instructions for your response:
1. Ground your answer in the given context, integrating its wisdom naturally.
2. Provide a complete, well-rounded explanation.
3. If the context is about compassion, respond warmly and empathetically.
   If the context is about knowledge, respond with clarity and depth.
4. Always inspire the reader — leave them with hope, strength, or a deeper perspective.
5. Use simple, graceful language that is easy to follow.
6. Do not merely summarize the context; weave it into a meaningful, life-affirming answer.
7. Try to keep the answer short unless asked for detailed answer.
8. Answer in language of Question
9. In case question is not clear or not related to context , dont answer and apologise humbly


Context: {context}

Question: {question}
"""
    # Append assistant message placeholder
    chat_pairs.append((question, ""))

    elapsed = time.time() - start_time
    logging.info(f"Total retrieval (pre-LLM) took {elapsed:.2f} sec")

    # Stream response from Ollama
    try:
        t_llm = time.time()
        for chunk in ollama.chat(model=MODEL_NAME, messages=[{"role": "user", "content": user_prompt}], stream=True):
            text_piece = chunk["message"].get("content", "")
            if text_piece:
                chat_pairs[-1] = (question, chat_pairs[-1][1] + text_piece)
                yield chat_pairs
        llm_time = time.time() - t_llm
        logging.info(f"LLM streaming took {llm_time:.2f} sec")
        answer = chat_pairs[-1][1]
        answer += f"\n\n⏱️ Time taken:  {llm_time:.2f} sec \n"
        chat_pairs[-1] = (question, answer)
        log_history(question, answer)
        yield chat_pairs
    except Exception as e:
        error_msg = f"❌ Streaming error: {e}"
        chat_pairs[-1] = (question, error_msg)
        log_history(question, error_msg)
        yield chat_pairs

# ---------------- GRADIO UI ----------------
def launch_ui():
    global faiss_store
    index, docs, metadata = faiss_store
    authors = ["All"] + get_authors(metadata)

    with gr.Blocks() as demo:
        gr.Markdown("# 📚 RAG Chatbot with Author Filter")

        with gr.Row():
            q_input = gr.Textbox(label="Your Question", lines=2)
            author_dropdown = gr.Dropdown(choices=authors, value="All", label="Author")

        chatbot = gr.Chatbot(label="Chatbot", height=500)
        ask_btn = gr.Button("Ask")

        ask_btn.click(
            fn=query_rag_stream,
            inputs=[q_input, author_dropdown],
            outputs=[chatbot]
        )

    demo.launch(server_name="0.0.0.0", server_port=7860)

if __name__ == "__main__":
    folder = "/Users/antarikshbhardwaj/Documents/RAG/App Books/"
    if not os.path.exists(INDEX_FILE):
        build_faiss_index(folder)

    # Load FAISS index once at startup
    start_time = time.time()
    faiss_store = load_faiss_index()
    elapsed = time.time() - start_time
    logging.info(f"✅ FAISS index loaded in {elapsed:.2f} seconds.")

    # Pass the loaded index to the UI
    launch_ui()
