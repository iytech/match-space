import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/property.dart';
import '../../services/booking_service.dart';

class BookViewingSheet extends StatefulWidget {
  final Property property;
  const BookViewingSheet({super.key, required this.property});
  @override
  State<BookViewingSheet> createState() => _BookViewingSheetState();
}

class _BookViewingSheetState extends State<BookViewingSheet> {
  final _service = BookingService();
  final _note = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_date == null || _time == null) return;
    setState(() => _busy = true);
    final scheduled = DateTime(_date!.year, _date!.month, _date!.day,
        _time!.hour, _time!.minute);
    await _service.request(
      propertyId: widget.property.id,
      ownerId: widget.property.ownerId,
      scheduledFor: scheduled,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Viewing request sent to the owner.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book a viewing',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(widget.property.title,
                style: const TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_date == null
                      ? 'Pick date'
                      : '${_date!.day}/${_date!.month}/${_date!.year}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());
                    if (t != null) setState(() => _time = t);
                  },
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(_time == null
                      ? 'Pick time'
                      : _time!.format(context)),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration:
                  const InputDecoration(hintText: 'Add a note (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_date == null || _time == null || _busy)
                    ? null
                    : _submit,
                child: Text(_busy ? 'Sending…' : 'Request viewing'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
