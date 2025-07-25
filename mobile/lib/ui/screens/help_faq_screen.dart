// lib/ui/screens/help_faq_screen.dart
import 'package:flutter/material.dart';

class HelpFAQScreen extends StatefulWidget {
  const HelpFAQScreen({Key? key}) : super(key: key);

  @override
  State<HelpFAQScreen> createState() => _HelpFAQScreenState();
}

class _HelpFAQScreenState extends State<HelpFAQScreen> {
  String _selectedCategory = 'general';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, List<Map<String, String>>> _faqData = {
    'general': [
      {
        'question': 'Comment fonctionne Teyago Services ?',
        'answer':
            'Teyago Services est une plateforme qui met en relation les clients avec des prestataires de services qualifiés. Les clients peuvent publier leurs projets et recevoir des devis, tandis que les prestataires peuvent proposer leurs services et répondre aux demandes.',
      },
      {
        'question': 'Comment créer un compte ?',
        'answer':
            'Vous pouvez créer un compte en tant que client ou prestataire en cliquant sur "S\'inscrire" et en remplissant le formulaire d\'inscription avec vos informations personnelles.',
      },
      {
        'question': 'L\'application est-elle gratuite ?',
        'answer':
            'L\'inscription et la navigation sur la plateforme sont gratuites. Des frais peuvent s\'appliquer lors de la finalisation de certains services ou transactions.',
      },
    ],
    'clients': [
      {
        'question': 'Comment publier un projet ?',
        'answer':
            'Connectez-vous à votre compte client, cliquez sur "Publier un projet", décrivez votre besoin, ajoutez votre budget et les compétences requises. Les prestataires pourront ensuite vous envoyer leurs propositions.',
      },
      {
        'question': 'Comment choisir un prestataire ?',
        'answer':
            'Consultez les profils des prestataires, leurs avis, leurs réalisations précédentes et leurs tarifs. Vous pouvez également échanger avec eux via la messagerie intégrée avant de faire votre choix.',
      },
      {
        'question': 'Comment payer un prestataire ?',
        'answer':
            'Les paiements s\'effectuent de manière sécurisée via la plateforme. Vous pouvez payer par carte bancaire, virement ou mobile money selon les options disponibles.',
      },
      {
        'question': 'Que faire si je ne suis pas satisfait du service ?',
        'answer':
            'Vous pouvez ouvrir un litige depuis votre espace client. Notre équipe de médiation interviendra pour résoudre le problème. Vous pouvez également laisser un avis pour informer les autres utilisateurs.',
      },
    ],
    'providers': [
      {
        'question': 'Comment créer mon profil prestataire ?',
        'answer':
            'Après inscription, complétez votre profil avec vos compétences, votre expérience, vos tarifs et ajoutez un portfolio de vos réalisations. Plus votre profil est détaillé, plus vous aurez de chances d\'être contacté.',
      },
      {
        'question': 'Comment répondre à un projet ?',
        'answer':
            'Parcourez les projets dans votre domaine, cliquez sur ceux qui vous intéressent et envoyez votre proposition avec un devis détaillé et un délai de réalisation.',
      },
      {
        'question': 'Comment fixer mes tarifs ?',
        'answer':
            'Vous êtes libre de fixer vos tarifs. Consultez les prix pratiqués par d\'autres prestataires dans votre domaine pour rester compétitif tout en valorisant votre expertise.',
      },
      {
        'question': 'Comment obtenir plus de clients ?',
        'answer':
            'Maintenez un profil à jour, répondez rapidement aux demandes, proposez des tarifs compétitifs, et accumulez des avis positifs en livrant un travail de qualité.',
      },
    ],
    'payments': [
      {
        'question': 'Quels sont les moyens de paiement acceptés ?',
        'answer':
            'Nous acceptons les cartes bancaires (Visa, MasterCard), les virements bancaires et le mobile money (selon votre région).',
      },
      {
        'question': 'Quand suis-je débité ?',
        'answer':
            'Le paiement est effectué lorsque vous confirmez l\'acceptation de la prestation et que le prestataire commence le travail. Pour certains services, un acompte peut être demandé.',
      },
      {
        'question': 'Comment obtenir une facture ?',
        'answer':
            'Une facture électronique est automatiquement générée et envoyée par email après chaque transaction. Vous pouvez également la télécharger depuis votre espace personnel.',
      },
      {
        'question': 'Comment obtenir un remboursement ?',
        'answer':
            'En cas de problème avéré, vous pouvez demander un remboursement via la procédure de litige. Chaque demande est étudiée au cas par cas par notre équipe.',
      },
    ],
    'technical': [
      {
        'question': 'L\'application ne fonctionne pas correctement',
        'answer':
            'Vérifiez votre connexion internet, fermez et relancez l\'application. Si le problème persiste, mettez à jour l\'application ou contactez notre support technique.',
      },
      {
        'question': 'Comment changer ma langue ?',
        'answer':
            'Allez dans Paramètres > Langue et sélectionnez votre langue préférée parmi français, anglais ou portugais.',
      },
      {
        'question': 'Mes notifications ne fonctionnent pas',
        'answer':
            'Vérifiez que les notifications sont activées dans les paramètres de l\'application et dans les paramètres de votre téléphone.',
      },
      {
        'question': 'Comment sauvegarder mes données ?',
        'answer':
            'Vos données sont automatiquement sauvegardées sur nos serveurs sécurisés. Vous pouvez également exporter vos informations depuis votre profil.',
      },
    ],
  };

  List<Map<String, String>> get _filteredFAQs {
    final faqs = _faqData[_selectedCategory] ?? [];
    if (_searchQuery.isEmpty) return faqs;

    return faqs.where((faq) {
      return faq['question']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Aide et FAQ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher une question...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF142FE2)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Catégories
          Container(
            color: Colors.white,
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('general', 'Général'),
                _buildCategoryChip('clients', 'Clients'),
                _buildCategoryChip('providers', 'Prestataires'),
                _buildCategoryChip('payments', 'Paiements'),
                _buildCategoryChip('technical', 'Technique'),
              ],
            ),
          ),

          const SizedBox(height: 1),

          // Liste des FAQ
          Expanded(
            child: _filteredFAQs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFAQs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFAQs[index];
                      return _buildFAQItem(faq['question']!, faq['answer']!);
                    },
                  ),
          ),

          // Section contact
          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
            _searchQuery = '';
            _searchController.clear();
          });
        },
        selectedColor: const Color(0xFF142FE2).withOpacity(0.2),
        checkmarkColor: const Color(0xFF142FE2),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF142FE2) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
        iconColor: const Color(0xFF142FE2),
        collapsedIconColor: Colors.grey[600],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune question trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Vous ne trouvez pas la réponse ?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Ouvrir le chat support
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat support - À venir'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF142FE2),
                    side: const BorderSide(color: Color(0xFF142FE2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Ouvrir l'email support
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email support - À venir'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF142FE2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
