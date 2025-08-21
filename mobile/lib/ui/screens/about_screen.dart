// lib/ui/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../providers/language_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutTeyaGo),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo et titre
            Center(
              child: Column(
                children: [
                  Container(
                    // padding: const EdgeInsets.all(20),
                    // decoration: BoxDecoration(
                    //   gradient: LinearGradient(
                    //     colors: [Colors.blue.shade600, Colors.blue.shade800],
                    //     begin: Alignment.topLeft,
                    //     end: Alignment.bottomRight,
                    //   ),
                    //   borderRadius: BorderRadius.circular(20),
                    //   boxShadow: [
                    //     BoxShadow(
                    //       color: Colors.blue.withOpacity(0.3),
                    //       blurRadius: 15,
                    //       offset: const Offset(0, 5),
                    //     ),
                    //   ],
                    // ),
                    // child: const Text(
                    //   'TeyaGO',
                    //   style: TextStyle(
                    //     fontSize: 32,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.white,
                    //     letterSpacing: 1.5,
                    //   ),
                    // ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.yourTrustedServicesGuide,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Contenu principal
            _buildContentCard(
              context,
              l10n.aboutTeyaGo,
              _getAboutContent(context),
              Icons.info_outline,
            ),
            
            const SizedBox(height: 24),
            
            // Section fonctionnalités
            // _buildFeaturesSection(context, l10n),
            
            const SizedBox(height: 32),
            
            // Footer avec version
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© 2025 TeyaGO',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, AppLocalizations l10n) {
    final features = [
      {
        'icon': Icons.search,
        'title': l10n.exploreServices,
        'description': l10n.exploreServicesDescription,
      },
      {
        'icon': Icons.compare_arrows,
        'title': l10n.compareProviders,
        'description': l10n.compareProvidersDescription,
      },
      {
        'icon': Icons.request_quote,
        'title': l10n.requestQuotes,
        'description': l10n.requestQuotesDescription,
      },
      {
        'icon': Icons.star_rate,
        'title': l10n.shareExperience,
        'description': l10n.shareExperienceDescription,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.keyFeatures,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => _buildFeatureItem(
          feature['icon'] as IconData,
          feature['title'] as String,
          feature['description'] as String,
        )).toList(),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.blue[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAboutContent(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.currentLanguageCode;
    
    switch (currentLang) {
      case 'pt':
        return 'Em geral, encontrar um serviço de confiança pode ser um desafio: falta de informações, contactos limitados e muita incerteza. O TeyaGo surgiu para facilitar essa procura.\n\n'
               'A nossa aplicação é uma plataforma de encontro entre particulares e prestadores de serviços em várias áreas: beleza, construção, saúde, eventos, transporte, serviços digitais e muito mais.\n\n'
               'Aqui você pode explorar opções, comparar, pedir um orçamento e partilhar a sua experiência.\n\n'
               'O TeyaGo não escolhe por si, mas dá-lhe as ferramentas para tomar uma decisão informada e encontrar o que procura com mais facilidade.';
      
      case 'en':
        return 'Generally, finding a trusted service can be a real challenge: lack of information, limited contacts and many uncertainties. TeyaGo was created to simplify this search.\n\n'
               'Our application is a meeting platform between individuals and service providers in many areas: beauty, construction, health, events, transport, digital services and much more.\n\n'
               'You can explore options, compare, request quotes and share your experience.\n\n'
               'TeyaGo does not choose for you, but gives you the tools to make an informed decision and find what you need more easily.';
      
      default: // français
        return 'En général, trouver un service de confiance peut être un vrai défi : manque d\'informations, contacts limités et beaucoup d\'incertitudes. TeyaGo est né pour simplifier cette recherche.\n\n'
               'Notre application est une plateforme de mise en relation entre particuliers et prestataires de services dans de nombreux domaines : beauté, construction, santé, événements, transport, services numériques et bien plus encore.\n\n'
               'Vous pouvez y explorer des options, comparer, demander un devis et partager votre expérience.\n\n'
               'TeyaGo ne choisit pas à votre place, mais vous donne les outils pour prendre une décision éclairée et trouver plus facilement ce dont vous avez besoin.';
    }
  }
}