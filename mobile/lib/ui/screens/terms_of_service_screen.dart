// lib/ui/screens/terms_of_service_screen.dart
import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Conditions d\'utilisation'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection(
              'Acceptation des conditions',
              [
                'En utilisant Teyago Services, vous acceptez d\'être lié par ces conditions d\'utilisation.',
                'Si vous n\'acceptez pas ces conditions, vous ne devez pas utiliser notre service.',
                'Nous nous réservons le droit de modifier ces conditions à tout moment.',
              ],
            ),
            _buildSection(
              'Description du service',
              [
                'Teyago Services est une plateforme de mise en relation entre clients et prestataires de services.',
                'Nous facilitons les connexions mais ne sommes pas partie prenante dans les transactions entre utilisateurs.',
                'La qualité des services fournis relève entièrement de la responsabilité des prestataires.',
              ],
            ),
            _buildSection(
              'Inscription et compte utilisateur',
              [
                'Vous devez fournir des informations exactes et complètes lors de votre inscription.',
                'Vous êtes responsable de la confidentialité de vos identifiants de connexion.',
                'Un seul compte par personne ou entité est autorisé.',
                'Nous nous réservons le droit de suspendre ou supprimer des comptes en cas de violation.',
              ],
            ),
            _buildSection(
              'Obligations des clients',
              [
                'Fournir des descriptions précises et complètes de vos projets.',
                'Payer les services commandés selon les conditions convenues.',
                'Traiter les prestataires avec respect et professionnalisme.',
                'Ne pas utiliser la plateforme à des fins illégales ou frauduleuses.',
              ],
            ),
            _buildSection(
              'Obligations des prestataires',
              [
                'Fournir des services conformes aux descriptions et aux délais convenus.',
                'Posséder les qualifications et autorisations nécessaires pour vos services.',
                'Maintenir un niveau de qualité professionnel.',
                'Respecter les délais et engagements pris envers les clients.',
              ],
            ),
            _buildSection(
              'Paiements et tarification',
              [
                'Les prix sont fixés librement par les prestataires.',
                'Les paiements s\'effectuent via notre plateforme sécurisée.',
                'Des frais de service peuvent s\'appliquer sur les transactions.',
                'Les remboursements sont traités selon notre politique de litige.',
              ],
            ),
            _buildSection(
              'Propriété intellectuelle',
              [
                'Vous conservez la propriété de vos contenus mais nous accordez une licence d\'utilisation.',
                'Vous ne devez pas violer les droits de propriété intellectuelle d\'autrui.',
                'Notre marque, logo et contenus sont protégés par les droits d\'auteur.',
              ],
            ),
            _buildSection(
              'Limitation de responsabilité',
              [
                'Teyago Services agit uniquement comme intermédiaire.',
                'Nous ne sommes pas responsables de la qualité des services fournis.',
                'Notre responsabilité est limitée au montant des frais de service perçus.',
                'Nous ne garantissons pas la disponibilité continue du service.',
              ],
            ),
            _buildSection(
              'Résiliation',
              [
                'Vous pouvez fermer votre compte à tout moment.',
                'Nous pouvons suspendre ou résilier votre compte en cas de violation.',
                'Certaines obligations survivent à la résiliation du compte.',
              ],
            ),
            _buildSection(
              'Droit applicable',
              [
                'Ces conditions sont régies par le droit angolais.',
                'Tout litige sera soumis aux tribunaux compétents d\'Angola.',
                'En cas de conflit, la version française fait foi.',
              ],
            ),
            _buildContactInfo(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF142FE2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conditions d\'utilisation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF142FE2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrée en vigueur : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ces conditions d\'utilisation régissent votre accès et utilisation de la plateforme Teyago Services. Veuillez les lire attentivement.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF142FE2),
          ),
        ),
        const SizedBox(height: 12),
        ...content
            .map((text) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(
                              fontSize: 16, color: Color(0xFF142FE2))),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questions légales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF142FE2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pour toute question concernant ces conditions d\'utilisation :',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          _buildContactItem(Icons.email, 'legal@angolasservices.com'),
          _buildContactItem(Icons.phone, '+244 XXX XXX XXX'),
          _buildContactItem(Icons.location_on, 'Luanda, Angola'),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF142FE2)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
