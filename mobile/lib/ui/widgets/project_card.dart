// mobile/lib/ui/widgets/project_card.dart
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
      elevation: 2,
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            project.categoryName,
            style: const TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        if (project.urgency != 'low') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getUrgencyColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
                    fontWeight: FontWeight.w500,
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
                color: project.isFavorited == true 
                    ? Colors.red 
                    : Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
        if (project.hasUserOffered == true) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 12,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Offre envoyée',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
        fontWeight: FontWeight.w600,
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
      style: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
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
        ...displaySkills.map((skill) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            skill.name,
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
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${project.requiredSkills.length - 3}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w500,
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
                    fontWeight: FontWeight.w600,
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
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Icon(
                  project.remotePossible 
                      ? Icons.computer 
                      : Icons.location_on,
                  color: Colors.grey[600],
                  size: 16,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_outline,
                  color: Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${project.offersCount} offre${project.offersCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (project.timeSincePosted != null) ...[
              Text(
                project.timeSincePosted!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Color _getUrgencyColor() {
    switch (project.urgency) {
      case 'very_high':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}