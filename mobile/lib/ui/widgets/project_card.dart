// mobile/lib/ui/widgets/project_card.dart - Version corrigée

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/client_project.dart';

class ProjectCard extends StatelessWidget {
  final ClientProject project;
  final VoidCallback? onTap; // ← CHANGER en VoidCallback simple
  final VoidCallback? onFavoriteToggle;

  const ProjectCard({
    Key? key,
    required this.project,
    this.onTap,
    this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        // Navigation par défaut vers le détail du projet
        Navigator.pushNamed(
          context,
          '/project-detail',
          arguments: {'projectId': project.id},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et favori
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (onFavoriteToggle != null)
                    IconButton(
                      onPressed: onFavoriteToggle,
                      icon: Icon(
                        // ✅ CORRIGER ICI
                        project.isFavorited == true 
                            ? Icons.favorite        // Coeur plein si en favori
                            : Icons.favorite_border, // Coeur vide sinon
                        color: project.isFavorited == true 
                            ? Colors.red   // Rouge si en favori
                            : Colors.grey, // Gris sinon
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                project.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Informations du projet
              Row(
                children: [
                  // Budget
                  if (project.budgetDisplay.isNotEmpty) ...[
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      project.budgetDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  // Date limite
                  if (project.deadline != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(project.deadline!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Statut et nombre d'offres
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${project.offersCount} offre${project.offersCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (project.status) {
      case 'open':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (project.status) {
      case 'open':
        return 'Ouvert';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }
}