import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/review.dart';
import 'rating_stars.dart';

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({
    Key? key,
    required this.review,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec info utilisateur
          Row(
            children: [
              // Avatar utilisateur
              CircleAvatar(
                radius: 20,
                backgroundImage: review.userImageUrl.isNotEmpty
                    ? NetworkImage(review.userImageUrl)
                    : null,
                child: review.userImageUrl.isEmpty
                    ? Text(
                        review.userName.substring(0, 1),
                        style: const TextStyle(fontSize: 20),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Nom et date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(review.date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Note
              RatingStars(rating: review.rating),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Commentaire
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}