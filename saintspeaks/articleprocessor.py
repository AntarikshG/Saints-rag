def process_file(input_file, output_file):
    try:
        with open(input_file, "r", encoding="utf-8") as f:
            lines = f.readlines()

        processed_lines = []
        for line in lines:
            line = line.strip()
            # Escape single quotes inside the line
            line = line.replace("'", r"\'")

            # Wrap in single quotes if not already wrapped
            if not (line.startswith("'") and line.endswith("'")):
                line = f"'{line}'"

            processed_lines.append(line)

        # Join with literal \n\n between lines (not in quotes)
        final_text = r"\n\n".join(processed_lines)

        with open(output_file, "w", encoding="utf-8") as f:
            f.write(final_text)

        print(f"✅ Processed file saved as: {output_file}")

    except FileNotFoundError:
        print("❌ Error: Input file not found.")
    except Exception as e:
        print(f"❌ An error occurred: {e}")


if __name__ == "__main__":
    input_file = 'article.txt'
    output_file = "processed_" + input_file
    process_file(input_file, output_file)
