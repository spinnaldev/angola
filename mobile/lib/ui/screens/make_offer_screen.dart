// mobile/lib/ui/screens/make_offer_screen.dart - Version avec traductions
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../core/models/client_project.dart';
import '../../core/services/api_service.dart';
import '../../providers/auth_provider.dart';

class MakeOfferScreen extends StatefulWidget {
  final ClientProject project;

  const MakeOfferScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends State<MakeOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Contrôleurs de texte
  final _priceController = TextEditingController();
  final _deliveryTimeController = TextEditingController();
  final _messageController = TextEditingController();
  final _warrantyController = TextEditingController();

  // Variables de state
  bool _includesMaterials = false;
  bool _travelCostsIncluded = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Préremplir avec une estimation basée sur le budget du projet
    _estimatePrice();
  }

  void _estimatePrice() {
    if (widget.project.minBudget != null && widget.project.minBudget! > 0) {
      try {
        _priceController.text = widget.project.minBudget!.toInt().toString();
      } catch (e) {
        print('❌ Erreur conversion budget: $e');
        _priceController.text = '1000'; // Valeur par défaut
      }
    } else {
      switch (widget.project.budgetRange) {
        case 'moins_500':
          _priceController.text = '400';
          break;
        case '500_1000':
          _priceController.text = '750';
          break;
        case '1000_10000':
          _priceController.text = '2500';
          break;
        case '10000_plus':
          _priceController.text = '15000';
          break;
        default:
          _priceController.text = '1000';
      }
    }

    // Estimation du délai basée sur l'urgence
    switch (widget.project.urgency) {
      case 'high':
        _deliveryTimeController.text = '7';
        break;
      case 'medium':
        _deliveryTimeController.text = '14';
        break;
      case 'low':
        _deliveryTimeController.text = '30';
        break;
      default:
        _deliveryTimeController.text = '14';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.makeOffer,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              _buildProjectSummary(),
              _buildOfferForm(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildProjectSummary() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF142FE2).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF142FE2).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.projectToHandle,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.project.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.project.description,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.location_on,
                label: widget.project.location,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.account_balance_wallet,
                label: widget.project.budgetDisplay,
              ),
            ],
          ),
          if (widget.project.urgency != 'low') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.priority_high,
                  color: widget.project.urgency == 'high'
                      ? Colors.red
                      : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.project.urgencyLabel,
                  style: TextStyle(
                    color: widget.project.urgency == 'high'
                        ? Colors.red
                        : Colors.orange,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPricingSection(),
          const SizedBox(height: 24),
          _buildDeliverySection(),
          const SizedBox(height: 24),
          _buildMessageSection(),
          const SizedBox(height: 24),
          _buildOptionsSection(),
          const SizedBox(height: 24),
          _buildTipsSection(),
          const SizedBox(height: 100), // Espace pour le bouton fixe
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    final l10n = AppLocalizations.of(context)!;

    return _buildSection(
      title: l10n.pricing,
      icon: Icons.account_balance_wallet,
      children: [
        TextFormField(
          controller: _priceController,
          decoration: InputDecoration(
            labelText: l10n.proposedPrice,
            hintText: l10n.allInclusivePrice,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.account_balance_wallet),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.priceRequired;
            }
            final price = double.tryParse(value);
            if (price == null || price <= 0) {
              return l10n.enterValidPrice;
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          l10n.priceIncludesAllCosts,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    final l10n = AppLocalizations.of(context)!;

    return _buildSection(
      title: l10n.deliveryTime,
      icon: Icons.schedule,
      children: [
        TextFormField(
          controller: _deliveryTimeController,
          decoration: InputDecoration(
            labelText: l10n.deliveryTimeInDays,
            hintText: l10n.daysToCompleteProject,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.schedule),
            suffixText: l10n.days,
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.deliveryTimeRequired;
            }
            final days = int.tryParse(value);
            if (days == null || days <= 0) {
              return l10n.enterValidDeliveryTime;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    final l10n = AppLocalizations.of(context)!;

    return _buildSection(
      title: l10n.accompanimentMessage,
      icon: Icons.message,
      children: [
        TextFormField(
          controller: _messageController,
          decoration: InputDecoration(
            labelText: l10n.detailedProposal,
            hintText: l10n.explainYourApproach,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.messageRequired;
            }
            if (value.length < 50) {
              return l10n.messageMinLength;
            }
            return null;
          },
          maxLength: 1500,
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    final l10n = AppLocalizations.of(context)!;

    return _buildSection(
      title: l10n.optionsAndWarranties,
      icon: Icons.security,
      children: [
        CheckboxListTile(
          title: Text(l10n.materialsIncluded),
          subtitle: Text(l10n.priceIncludesMaterials),
          value: _includesMaterials,
          onChanged: (bool? value) {
            setState(() {
              _includesMaterials = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(l10n.travelCostsIncluded),
          subtitle: Text(l10n.noAdditionalTravelCosts),
          value: _travelCostsIncluded,
          onChanged: (bool? value) {
            setState(() {
              _travelCostsIncluded = value ?? true;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _warrantyController,
          decoration: InputDecoration(
            labelText: l10n.warrantyMonths,
            hintText: 'Ex: 12',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.verified_user),
            suffixText: l10n.months,
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.attractiveOfferTips,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.offerTipsContent,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF142FE2), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildSubmitButton() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142FE2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    l10n.sendMyOffer,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitOffer() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final offerData = {
        'project': widget.project.id,
        'proposed_price': double.parse(_priceController.text),
        'delivery_time': int.parse(_deliveryTimeController.text),
        'message': _messageController.text.trim(),
        'includes_materials': _includesMaterials,
        'warranty_period': _warrantyController.text.isNotEmpty
            ? int.parse(_warrantyController.text)
            : null,
        'travel_costs_included': _travelCostsIncluded,
      };

      await apiService.createProjectOffer(offerData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.offerSentSuccessfully),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = l10n.errorSendingOffer;
        if (e.toString().contains('déjà fait une offre')) {
          errorMessage = l10n.alreadyMadeOfferForProject;
        } else if (e.toString().contains('plus d\'offres')) {
          errorMessage = l10n.projectNoLongerAcceptsOffers;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _deliveryTimeController.dispose();
    _messageController.dispose();
    _warrantyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
