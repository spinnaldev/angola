// lib/ui/widgets/dispute_comment_form.dart - VERSION CORRIGÉE
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ✅ AJOUT des traductions
import '../../providers/dispute_provider.dart';
import '../screens/disputes/add_evidence_screen.dart';

class DisputeCommentForm extends StatefulWidget {
  final int disputeId;
  final VoidCallback onCommentAdded;

  const DisputeCommentForm({
    Key? key,
    required this.disputeId,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  _DisputeCommentFormState createState() => _DisputeCommentFormState();
}

class _DisputeCommentFormState extends State<DisputeCommentForm> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ TRADUCTIONS
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addComment, // ✅ TRADUIT
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: l10n.writeYourComment, // ✅ TRADUIT
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEvidenceScreen(
                        disputeId: widget.disputeId,
                      ),
                    ),
                  ).then((_) => widget.onCommentAdded());
                },
                icon: const Icon(Icons.attach_file),
                label: Text(l10n.addEvidence), // ✅ TRADUIT
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(l10n.send), // ✅ TRADUIT
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ CORRECTION MAJEURE : Méthode réelle d'ajout de commentaire
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ✅ Appel de la vraie API via le provider
      final success = await Provider.of<DisputeProvider>(
        context, 
        listen: false
      ).addComment(
        widget.disputeId,
        _commentController.text.trim(),
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.commentAddedSuccessfully ?? 'Commentaire ajouté avec succès'), // ✅ TRADUIT avec fallback
              backgroundColor: Colors.green,
            ),
          );
          _commentController.clear();
          widget.onCommentAdded(); // Recharger les données
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorAddingComment ?? 'Erreur lors de l\'ajout du commentaire'), // ✅ TRADUIT avec fallback
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorTitle ?? 'Erreur'}: ${e.toString()}'), // ✅ TRADUIT avec fallback
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}