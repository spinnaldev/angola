// lib/ui/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
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
              'Collecte des informations',
              [
                'Nous collectons les informations que vous nous fournissez directement lors de votre inscription et utilisation de nos services.',
                'Ces informations incluent votre nom, adresse email, numéro de téléphone, et autres détails de profil.',
                'Nous collectons également des données techniques comme votre adresse IP, type de navigateur, et données d\'utilisation.',
              ],
            ),
            _buildSection(
              'Utilisation des données',
              [
                'Vos données sont utilisées pour fournir et améliorer nos services.',
                'Nous utilisons vos informations pour faciliter la mise en relation entre clients et prestataires.',
                'Nous pouvons vous envoyer des notifications relatives à votre compte et aux services.',
                'Vos données nous aident à personnaliser votre expérience et à améliorer notre plateforme.',
              ],
            ),
            _buildSection(
              'Partage des informations',
              [
                'Nous ne vendons jamais vos données personnelles à des tiers.',
                'Vos informations de profil peuvent être visibles par les autres utilisateurs selon vos paramètres de confidentialité.',
                'Nous pouvons partager des données agrégées et anonymisées à des fins statistiques.',
                'En cas d\'obligation légale, nous pouvons être amenés à divulguer certaines informations aux autorités compétentes.',
              ],
            ),
            _buildSection(
              'Protection des données',
              [
                'Nous utilisons des mesures de sécurité techniques et organisationnelles pour protéger vos données.',
                'Vos données sont stockées sur des serveurs sécurisés avec chiffrement.',
                'L\'accès à vos données est strictement limité aux employés autorisés.',
                'Nous effectuons régulièrement des audits de sécurité pour maintenir le plus haut niveau de protection.',
              ],
            ),
            _buildSection(
              'Vos droits',
              [
                'Vous avez le droit d\'accéder à vos données personnelles que nous détenons.',
                'Vous pouvez demander la correction ou la suppression de vos données.',
                'Vous pouvez vous opposer au traitement de vos données à des fins de marketing.',
                'Vous avez le droit à la portabilité de vos données.',
              ],
            ),
            _buildSection(
              'Cookies et technologies similaires',
              [
                'Nous utilisons des cookies pour améliorer votre expérience utilisateur.',
                'Les cookies nous aident à mémoriser vos préférences et à analyser l\'utilisation de notre service.',
                'Vous pouvez configurer votre navigateur pour refuser les cookies, mais cela peut affecter certaines fonctionnalités.',
              ],
            ),
            _buildSection(
              'Conservation des données',
              [
                'Nous conservons vos données aussi longtemps que nécessaire pour fournir nos services.',
                'Après suppression de votre compte, certaines données peuvent être conservées pour des raisons légales.',
                'Les données de facturation sont conservées selon les obligations comptables et fiscales.',
              ],
            ),
            _buildSection(
              'Modifications de cette politique',
              [
                'Nous pouvons mettre à jour cette politique de confidentialité de temps en temps.',
                'Les modifications importantes vous seront notifiées par email ou via l\'application.',
                'L\'utilisation continue de nos services après modification constitue votre acceptation des nouvelles conditions.',
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
            'Protection de vos données personnelles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF142FE2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dernière mise à jour : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chez Angola Services, nous nous engageons à protéger votre vie privée et vos données personnelles. Cette politique explique comment nous collectons, utilisons et protégeons vos informations.',
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
        ...content.map((text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16, color: Color(0xFF142FE2))),
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
        )).toList(),
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
            'Nous contacter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF142FE2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pour toute question concernant cette politique de confidentialité ou vos données personnelles, vous pouvez nous contacter :',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          _buildContactItem(Icons.email, 'privacy@angolasservices.com'),
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