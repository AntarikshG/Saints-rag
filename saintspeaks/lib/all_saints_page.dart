import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talk_with_saints/articlesquotes_en.dart';
import 'package:talk_with_saints/articlesquotes_hi.dart';
import 'package:talk_with_saints/articlesquotes_de.dart';
import 'package:talk_with_saints/articlesquotes_kn.dart';
import 'package:talk_with_saints/articlesquotes_bn.dart';
import 'package:talk_with_saints/articlesquotes_sa.dart';
import 'package:talk_with_saints/articlesquotes_ta.dart';
import 'package:talk_with_saints/articlesquotes_te.dart';
import 'package:talk_with_saints/articlesquotes_ml.dart';
import 'package:talk_with_saints/articlesquotes_mr.dart';
import 'package:talk_with_saints/l10n/app_localizations.dart';
import 'package:talk_with_saints/main.dart';

class AllSaintsPage extends StatefulWidget {
  final String userName;
  final VoidCallback onBadgeRefresh;

  const AllSaintsPage({
    Key? key,
    required this.userName,
    required this.onBadgeRefresh,
  }) : super(key: key);

  @override
  _AllSaintsPageState createState() => _AllSaintsPageState();
}

class _AllSaintsPageState extends State<AllSaintsPage> {
  // Helper method to get saints list based on language
  List<dynamic> _getSaintsForLanguage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return saintsHi;
      case 'de':
        return saintsDe;
      case 'kn':
        return saintsKn;
      case 'bn':
        return saintsBn;
      case 'sa':
        return saintsSa;
      case 'ta':
        return saintsTa;
      case 'te':
        return saintsTe;
      case 'ml':
        return saintsMl;
      case 'mr':
        return saintsMr;
      default:
        return saintsEn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final languageCode = Localizations.localeOf(context).languageCode;
    final List<dynamic> saintList = _getSaintsForLanguage(languageCode);

    // Theme-aware gradients
    final mainGradient = brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
              Colors.black,
            ],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.shade50,
              Colors.orange.shade50,
              Colors.white,
            ],
          );

    final appBarGradient = brightness == Brightness.dark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey.shade900, Colors.grey.shade800],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepOrange.shade100.withOpacity(0.9),
              Colors.orange.shade50.withOpacity(0.9),
            ],
          );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          loc.saintsOfBharat,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: appBarGradient,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: mainGradient,
          ),
          child: Column(
            children: [
              SizedBox(height: 100), // Space for AppBar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text(
                  loc.chooseSpiritualGuide,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: brightness == Brightness.dark
                            ? Colors.orange.shade300
                            : Colors.deepOrange.shade800,
                        fontSize: 20,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: saintList.length,
                  itemBuilder: (context, i) => Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(20),
                    shadowColor: Colors.deepOrange.withOpacity(0.25),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: brightness == Brightness.dark
                              ? [
                                  Colors.grey.shade800,
                                  Colors.grey.shade900,
                                ]
                              : [
                                  Colors.white,
                                  Colors.deepOrange.shade50,
                                ],
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SaintPage(
                              saint: saintList[i],
                              userName: widget.userName,
                            ),
                          ),
                        ).then((_) => widget.onBadgeRefresh()),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Hero(
                                tag: 'saint_${saintList[i].id}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.deepOrange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 27,
                                      backgroundImage: saintList[i].image.startsWith('assets/')
                                          ? AssetImage(saintList[i].image) as ImageProvider
                                          : NetworkImage(saintList[i].image),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                saintList[i].name,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: brightness == Brightness.dark
                                      ? Colors.orange.shade300
                                      : Colors.deepOrange.shade800,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
