import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';

class ReviewsSection extends StatefulWidget {
  final String propertyId;
  final List<Review> reviews;
  final double avgRating;
  final VoidCallback onAdded;
  const ReviewsSection({
    super.key,
    required this.propertyId,
    required this.reviews,
    required this.avgRating,
    required this.onAdded,
  });
  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  final _service = ReviewService();
  final _comment = TextEditingController();
  int _rating = 5;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_comment.text.trim().isEmpty) return;
    setState(() => _busy = true);
    await _service.add(
        propertyId: widget.propertyId,
        rating: _rating,
        comment: _comment.text.trim());
    _comment.clear();
    setState(() => _busy = false);
    widget.onAdded();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 10),
          if (widget.reviews.isNotEmpty) ...[
            const Icon(Icons.star_rounded, color: AppColors.ochre, size: 20),
            Text(' ${widget.avgRating.toStringAsFixed(1)} '
                '(${widget.reviews.length})'),
          ],
        ]),
        const SizedBox(height: 16),
        if (auth.isLoggedIn) ...[
          Row(children: List.generate(5, (i) {
            return IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.ochre,
              ),
              onPressed: () => setState(() => _rating = i + 1),
            );
          })),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(
                hintText: 'Share your experience with this property…'),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Posting…' : 'Post review'),
            ),
          ),
          const Divider(height: 32),
        ],
        if (widget.reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No reviews yet. Be the first to share your thoughts.',
                style: TextStyle(color: AppColors.inkSoft)),
          )
        else
          ...widget.reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.terracottaSoft,
                      child: Text(
                          initialOf(r.authorName),
                          style: const TextStyle(
                              color: AppColors.terracottaDark,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(r.authorName ?? 'User',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text(Formatters.timeAgo(r.createdAt),
                                style: const TextStyle(
                                    color: AppColors.inkFaint, fontSize: 12)),
                          ]),
                          Row(
                              children: List.generate(
                                  5,
                                  (i) => Icon(
                                        i < r.rating
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 15,
                                        color: AppColors.ochre,
                                      ))),
                          const SizedBox(height: 4),
                          Text(r.comment,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}
