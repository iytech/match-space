import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/property_provider.dart';
import '../../services/property_service.dart';
import '../../services/storage_service.dart';
import '../../services/subscription_service.dart';

class _PendingMedia {
  final Uint8List bytes;
  final String name;
  final String contentType;
  final bool isVideo;
  _PendingMedia(this.bytes, this.name, this.contentType, this.isVideo);
}

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});
  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _form = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _storage = StorageService();
  final _service = PropertyService();
  final _subs = SubscriptionService();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _beds = TextEditingController(text: '3');
  final _baths = TextEditingController(text: '2');
  final _area = TextEditingController(text: '120');
  final _leaseTerm = TextEditingController(text: '2');

  String? _titleDocument;
  static const _titleDocOptions = [
    'Certificate of Occupancy (C of O)',
    'Deed of Assignment',
    'Governor\u2019s Consent',
    'Registered Survey',
    'Excision / Gazette',
    'Family Receipt',
  ];

  PropertyType _type = PropertyType.house;
  ListingPurpose _purpose = ListingPurpose.sale;
  String _state = 'FCT Abuja';
  final Set<String> _amenities = {};
  final List<_PendingMedia> _media = [];
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _title, _desc, _price, _city, _address, _beds, _baths, _area, _leaseTerm
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    for (final f in files) {
      final bytes = await f.readAsBytes();
      _media.add(_PendingMedia(
          bytes, f.name, f.mimeType ?? 'image/jpeg', false));
    }
    setState(() {});
  }

  Future<void> _pickVideo() async {
    final f = await _picker.pickVideo(source: ImageSource.gallery);
    if (f != null) {
      final bytes = await f.readAsBytes();
      _media.add(
          _PendingMedia(bytes, f.name, f.mimeType ?? 'video/mp4', true));
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_media.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add at least one photo of the property.')));
      return;
    }
    final auth = context.read<AuthProvider>();
    final profile = auth.profile!;

    // Enforce free-tier listing cap.
    if (!profile.isPremium) {
      final count = await _subs.activeListingCount(profile.id);
      if (count >= AppConfig.freeListingLimit) {
        if (mounted) _showUpgrade();
        return;
      }
    }

    setState(() => _busy = true);
    try {
      final media = <Map<String, dynamic>>[];
      for (var i = 0; i < _media.length; i++) {
        final m = _media[i];
        final url = await _storage.uploadPropertyMedia(
          bytes: m.bytes,
          fileName: m.name,
          contentType: m.contentType,
        );
        media.add({'url': url, 'is_video': m.isVideo, 'position': i});
      }

      final property = Property(
        id: '',
        ownerId: profile.id,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        type: _type,
        purpose: _purpose,
        status: PropertyStatus.pending,
        price: num.tryParse(_price.text.replaceAll(',', '')) ?? 0,
        state: _state,
        city: _city.text.trim(),
        address: _address.text.trim(),
        bedrooms: _type == PropertyType.land ? 0 : (int.tryParse(_beds.text) ?? 0),
        bathrooms: _type == PropertyType.land ? 0 : (int.tryParse(_baths.text) ?? 0),
        areaSqm: num.tryParse(_area.text) ?? 0,
        leaseTermYears: _purpose == ListingPurpose.lease
            ? int.tryParse(_leaseTerm.text)
            : null,
        titleDocument: _type == PropertyType.land ? _titleDocument : null,
        amenities: _amenities.toList(),
        media: const [],
        featured: profile.isPremium,
        createdAt: DateTime.now(),
      );

      await _service.create(property, media);
      if (mounted) {
        context.read<PropertyProvider>().loadHome();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Listing submitted! It will go live after admin approval.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showUpgrade() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Listing limit reached'),
        content: Text(
            'Free accounts can have up to ${AppConfig.freeListingLimit} active '
            'listings. Upgrade to Premium for unlimited listings and featured '
            'placement.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/subscription');
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    // Gate: only owners, agents, or admins can create listings.
    if (profile != null && !profile.canListProperties) {
      return Scaffold(
        appBar: AppBar(title: const Text('List a property')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.terracottaSoft.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_outlined,
                        size: 34, color: AppColors.terracotta),
                  ),
                  const SizedBox(height: 18),
                  Text('Listing is for owners & agents',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text(
                    'Your account is set up as a Seeker. Switch your account '
                    'type to Owner or Agent in your profile to start listing '
                    'properties.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/profile'),
                    icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                    label: const Text('Update account type'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('List a property')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _sectionTitle('Photos & video'),
                _mediaPicker(),
                const SizedBox(height: 24),
                _sectionTitle('Basics'),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                      labelText: 'Listing title',
                      hintText: 'e.g. 4-bed duplex in Rayfield'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the property, neighbourhood, etc.'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<PropertyType>(
                      value: _type,
                      decoration:
                          const InputDecoration(labelText: 'Type'),
                      items: PropertyType.values
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                  AppOptions.propertyTypeLabels[t] ?? t.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<ListingPurpose>(
                      value: _purpose,
                      decoration:
                          const InputDecoration(labelText: 'Purpose'),
                      items: const [
                        DropdownMenuItem(
                            value: ListingPurpose.sale,
                            child: Text('For sale')),
                        DropdownMenuItem(
                            value: ListingPurpose.rent,
                            child: Text('For rent')),
                        DropdownMenuItem(
                            value: ListingPurpose.lease,
                            child: Text('For lease')),
                        DropdownMenuItem(
                            value: ListingPurpose.shortlet,
                            child: Text('Short-let (weekly)')),
                      ],
                      onChanged: (v) => setState(() => _purpose = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: _purpose == ListingPurpose.shortlet
                          ? 'Price per week (₦)'
                          : (_purpose == ListingPurpose.rent ||
                                  _purpose == ListingPurpose.lease)
                              ? 'Price per year (₦)'
                              : 'Price (₦)',
                      prefixText: '₦ '),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                _sectionTitle('Location'),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _state,
                      decoration:
                          const InputDecoration(labelText: 'State'),
                      items: AppOptions.states
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _state = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _city,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  decoration:
                      const InputDecoration(labelText: 'Street address'),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Details'),
                if (_type == PropertyType.land)
                  // Land: no beds/baths — show area + title document instead.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _numField(_area, 'Plot size (m²)', Icons.straighten),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _titleDocument,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Title document',
                          prefixIcon:
                              Icon(Icons.description_outlined, size: 18),
                        ),
                        items: _titleDocOptions
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _titleDocument = v),
                      ),
                    ],
                  )
                else
                  Row(children: [
                    Expanded(
                        child:
                            _numField(_beds, 'Bedrooms', Icons.bed_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _numField(
                            _baths, 'Bathrooms', Icons.bathtub_outlined)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _numField(_area, 'Area m²', Icons.straighten)),
                  ]),
                if (_purpose == ListingPurpose.lease) ...[
                  const SizedBox(height: 12),
                  _numField(
                      _leaseTerm, 'Lease term (years)', Icons.schedule),
                ],
                const SizedBox(height: 24),
                _sectionTitle('Amenities'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppOptions.amenities.map((a) {
                    final sel = _amenities.contains(a);
                    return FilterChip(
                      label: Text(a),
                      selected: sel,
                      selectedColor: AppColors.terracottaSoft,
                      checkmarkColor: AppColors.terracottaDark,
                      onSelected: (v) => setState(() {
                        v ? _amenities.add(a) : _amenities.remove(a);
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Submit for approval'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t, style: Theme.of(context).textTheme.titleLarge),
      );

  Widget _numField(
          TextEditingController c, String label, IconData icon) =>
      TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration:
            InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18)),
      );

  Widget _mediaPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: const Text('Add photos'),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _pickVideo,
            icon: const Icon(Icons.videocam_outlined, size: 18),
            label: const Text('Add video'),
          ),
        ]),
        if (_media.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _media.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final m = _media[i];
                return Stack(children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: m.isVideo
                        ? Container(
                            color: AppColors.slate800,
                            child: const Icon(Icons.play_circle_fill,
                                color: Colors.white, size: 32))
                        : Image.memory(m.bytes, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _media.removeAt(i)),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ],
      ],
    );
  }
}
