// lib/ui/widgets/dispute_comment_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          const Text(
            'Ajouter un commentaire',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Écrivez votre commentaire...',
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
                label: const Text('Ajouter une preuve'),
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
                    : const Text('Envoyer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Cette fonctionnalité nécessiterait une API pour ajouter des commentaires
      // Pour l'instant, on simule juste le comportement
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commentaire ajouté'),
            backgroundColor: Colors.green,
          ),
        );
        _commentController.clear();
        widget.onCommentAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
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