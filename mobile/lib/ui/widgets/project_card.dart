// mobile/lib/ui/widgets/project_card.dart - Version corrigée
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/models/client_project.dart';
import '../../providers/auth_provider.dart';

class ProjectCard extends StatelessWidget {
  final ClientProject project;
  final VoidCallback? onTap;
  final Function(ClientProject)? onFavoriteToggle;

  const ProjectCard({
    Key? key,
    required this.project,
    this.onTap,
    this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isProvider = user?.role == 'provider';

    return Card(
      color: Colors.grey[50],
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isProvider),
              const SizedBox(height: 12),
              _buildTitle(),
              const SizedBox(height: 8),
              _buildDescription(),
              const SizedBox(height: 12),
              _buildSkills(),
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isProvider) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF142FE2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            project.categoryName,
            style: const TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        if (project.urgency != 'low') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getUrgencyColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.priority_high,
                  color: _getUrgencyColor(),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  project.urgencyLabel,
                  style: TextStyle(
                    color: _getUrgencyColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (isProvider && onFavoriteToggle != null) ...[
          InkWell(
            onTap: () => onFavoriteToggle!(project),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                project.isFavorited == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                color:
                    project.isFavorited == true ? Colors.red : Colors.grey[600],
                size: 20,
              ),
            ),
          ),
        ],
        if (project.hasUserOffered == true) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  'Offre envoyée',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      project.title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Text(
      project.description,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSkills() {
    if (project.requiredSkills.isEmpty) {
      return const SizedBox.shrink();
    }

    // Afficher seulement les 3 premières compétences
    final displaySkills = project.requiredSkills.take(3).toList();
    final hasMore = project.requiredSkills.length > 3;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        // Correction : utiliser directement skill au lieu de skill.name
        ...displaySkills.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                skill, // skill est déjà une String
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )),
        if (hasMore) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF142FE2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${project.requiredSkills.length - 3}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Informations sur le budget
        Expanded(
          flex: 2,
          child: Row(
            children: [
              const Icon(
                Icons.euro,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  project.budgetDisplay,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Localisation
        if (project.location.isNotEmpty) ...[
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  project.remotePossible ? Icons.computer : Icons.location_on,
                  color: Colors.grey[600],
                  size: 14,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    project.remotePossible && project.location.isNotEmpty
                        ? 'Remote / ${project.location}'
                        : project.remotePossible
                            ? 'Remote'
                            : project.location,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Informations sur les offres et le temps
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    color: Colors.grey[600],
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${project.offersCount}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility,
                    color: Colors.grey[600],
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${project.viewsCount}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (project.timeSincePosted != null) ...[
                const SizedBox(height: 4),
                Text(
                  project.timeSincePosted!,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _getUrgencyColor() {
    switch (project.urgency) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
