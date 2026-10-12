import '../models/catalog_models.dart';

/// MOCK DATA ONLY. Replaced by Supabase repositories in the backend phase.
class MockData {
  MockData._();

  static String _img(String id) =>
      'https://images.unsplash.com/$id?auto=format&fit=crop&w=900&q=70';

  static final String heroImage = _img('photo-1560066984-138dadb4c035');

  static final List<SalonBranch> branches = [
    const SalonBranch(id: 'b1', name: 'Flagship Studio', area: 'City Centre'),
    const SalonBranch(id: 'b2', name: 'Garden Studio', area: 'Riverside'),
    const SalonBranch(id: 'b3', name: 'Metro Studio', area: 'Central Plaza'),
  ];

  static final List<ServiceCategory> categories = [
    ServiceCategory(
      id: 'hair',
      name: 'Haircuts',
      imageUrl: _img('photo-1522337360788-8b13dee7a37e'),
    ),
    ServiceCategory(
      id: 'colour',
      name: 'Colour',
      imageUrl: _img('photo-1560869713-7d0a29430803'),
    ),
    ServiceCategory(
      id: 'beard',
      name: 'Beard',
      imageUrl: _img('photo-1621605815971-fbc98d665033'),
    ),
    ServiceCategory(
      id: 'facial',
      name: 'Facials',
      imageUrl: _img('photo-1570172619644-dfd03ed5d881'),
    ),
    ServiceCategory(
      id: 'wax',
      name: 'Waxing',
      imageUrl: _img('photo-1540555700478-4be289fbecef'),
    ),
    ServiceCategory(
      id: 'nails',
      name: 'Nails',
      imageUrl: _img('photo-1604654894610-df63bc536371'),
    ),
    ServiceCategory(
      id: 'spa',
      name: 'Spa',
      imageUrl: _img('photo-1540555700478-4be289fbecef'),
    ),
    ServiceCategory(
      id: 'bridal',
      name: 'Bridal',
      imageUrl: _img('photo-1519741497674-611481863552'),
    ),
  ];

  static final List<Treatment> popularTreatments = [
    Treatment(
      id: 't1',
      name: 'Signature Cut & Style',
      imageUrl: _img('photo-1503951914875-452162b0f3f1'),
      price: 899,
      durationMin: 45,
    ),
    Treatment(
      id: 't2',
      name: 'Balayage Colour',
      imageUrl: _img('photo-1560869713-7d0a29430803'),
      price: 4499,
      durationMin: 150,
    ),
    Treatment(
      id: 't3',
      name: 'Hydrating Facial',
      imageUrl: _img('photo-1570172619644-dfd03ed5d881'),
      price: 1799,
      durationMin: 60,
    ),
    Treatment(
      id: 't4',
      name: 'Beard Sculpt & Shave',
      imageUrl: _img('photo-1621605815971-fbc98d665033'),
      price: 599,
      durationMin: 30,
    ),
  ];

  static final List<Stylist> stylists = [
    Stylist(
      id: 's1',
      name: 'Aarav Mehta',
      role: 'Creative Director',
      rating: 4.9,
      experienceYears: 12,
      imageUrl: _img('photo-1507003211169-0a1dd7228f2d'),
    ),
    Stylist(
      id: 's2',
      name: 'Naina Kapoor',
      role: 'Colour Specialist',
      rating: 4.8,
      experienceYears: 9,
      imageUrl: _img('photo-1494790108377-be9c29b29330'),
    ),
    Stylist(
      id: 's3',
      name: 'Rohan Verma',
      role: 'Master Barber',
      rating: 4.8,
      experienceYears: 8,
      imageUrl: _img('photo-1500648767791-00dcc994a43e'),
    ),
    Stylist(
      id: 's4',
      name: 'Isha Malhotra',
      role: 'Skin Therapist',
      rating: 4.7,
      experienceYears: 7,
      imageUrl: _img('photo-1438761681033-6461ffad8d80'),
    ),
  ];

  static const List<Offer> offers = [
    Offer(
      id: 'o1',
      title: 'First visit, 20% off',
      subtitle: 'On any service for new guests',
      code: 'WELCOME20',
    ),
    Offer(
      id: 'o2',
      title: 'Bridal consultation',
      subtitle: 'Complimentary trial look',
      code: 'BRIDE',
    ),
    Offer(
      id: 'o3',
      title: 'Weekday glow',
      subtitle: '15% off facials, Mon to Thu',
      code: 'GLOW15',
    ),
  ];
  static final List<Service> services = [
    Service(
      id: 'sv_cut',
      categoryId: 'hair',
      name: 'Signature Cut & Style',
      description: 'Consultation, precision cut, wash and finish.',
      imageUrl: _img('photo-1503951914875-452162b0f3f1'),
      price: 899,
      durationMin: 45,
      exclusiveGroup: 'haircut',
    ),
    Service(
      id: 'sv_blow',
      categoryId: 'hair',
      name: 'Blow Dry & Finish',
      description: 'Wash and a smooth, voluminous blow dry.',
      imageUrl: _img('photo-1522337360788-8b13dee7a37e'),
      price: 549,
      durationMin: 30,
      exclusiveGroup: 'finish',
    ),
    Service(
      id: 'sv_balayage',
      categoryId: 'colour',
      name: 'Balayage Colour',
      description: 'Hand-painted, sun-kissed dimension with toner.',
      imageUrl: _img('photo-1560869713-7d0a29430803'),
      price: 4499,
      durationMin: 150,
      exclusiveGroup: 'colour',
    ),
    Service(
      id: 'sv_gloss',
      categoryId: 'colour',
      name: 'Gloss & Tone Treatment',
      description: 'Shine-boosting gloss to refresh colour.',
      imageUrl: _img('photo-1560066984-138dadb4c035'),
      price: 1999,
      durationMin: 60,
      exclusiveGroup: 'colour',
    ),
    Service(
      id: 'sv_beard',
      categoryId: 'beard',
      name: 'Beard Sculpt & Shave',
      description: 'Shaping, hot towel and a clean razor finish.',
      imageUrl: _img('photo-1621605815971-fbc98d665033'),
      price: 599,
      durationMin: 30,
      exclusiveGroup: 'beard',
    ),
    Service(
      id: 'sv_shave',
      categoryId: 'beard',
      name: 'Classic Hot Towel Shave',
      description: 'Traditional straight-razor shave.',
      imageUrl: _img('photo-1621605815971-fbc98d665033'),
      price: 449,
      durationMin: 25,
      exclusiveGroup: 'beard',
    ),
    Service(
      id: 'sv_hydra',
      categoryId: 'facial',
      name: 'Hydrating Facial',
      description: 'Deep cleanse, mask and moisture boost.',
      imageUrl: _img('photo-1570172619644-dfd03ed5d881'),
      price: 1799,
      durationMin: 60,
      exclusiveGroup: 'facial',
    ),
    Service(
      id: 'sv_cleanup',
      categoryId: 'facial',
      name: 'Express Clean-up',
      description: 'Quick refresh for tired skin.',
      imageUrl: _img('photo-1570172619644-dfd03ed5d881'),
      price: 899,
      durationMin: 30,
      exclusiveGroup: 'facial',
    ),
    Service(
      id: 'sv_wax_arms',
      categoryId: 'wax',
      name: 'Arms Waxing',
      description: 'Gentle full-arm waxing for smooth skin.',
      imageUrl: _img('photo-1540555700478-4be289fbecef'),
      price: 499,
      durationMin: 20,
    ),
    Service(
      id: 'sv_wax_legs',
      categoryId: 'wax',
      name: 'Full Legs Waxing',
      description: 'Full-leg waxing with soothing aftercare.',
      imageUrl: _img('photo-1540555700478-4be289fbecef'),
      price: 899,
      durationMin: 40,
    ),
    Service(
      id: 'sv_mani',
      categoryId: 'nails',
      name: 'Classic Manicure',
      description: 'Shaping, cuticle care and polish.',
      imageUrl: _img('photo-1604654894610-df63bc536371'),
      price: 599,
      durationMin: 40,
    ),
    Service(
      id: 'sv_pedi',
      categoryId: 'nails',
      name: 'Spa Pedicure',
      description: 'Soak, scrub, massage and polish.',
      imageUrl: _img('photo-1604654894610-df63bc536371'),
      price: 799,
      durationMin: 50,
    ),
    Service(
      id: 'sv_head',
      categoryId: 'spa',
      name: 'Head & Shoulder Massage',
      description: 'Tension-releasing massage with warm oil.',
      imageUrl: _img('photo-1540555700478-4be289fbecef'),
      price: 699,
      durationMin: 30,
      exclusiveGroup: 'massage',
    ),
    Service(
      id: 'sv_body',
      categoryId: 'spa',
      name: 'Relaxing Body Massage',
      description: 'Full-body massage for deep relaxation.',
      imageUrl: _img('photo-1540555700478-4be289fbecef'),
      price: 2499,
      durationMin: 60,
      exclusiveGroup: 'massage',
    ),
    Service(
      id: 'sv_bridal',
      categoryId: 'bridal',
      name: 'Bridal Makeup & Styling',
      description: 'Complete bridal look with hair styling.',
      imageUrl: _img('photo-1519741497674-611481863552'),
      price: 14999,
      durationMin: 240,
      exclusiveGroup: 'bridal',
    ),
    Service(
      id: 'sv_trial',
      categoryId: 'bridal',
      name: 'Bridal Trial Session',
      description: 'Preview your look before the big day.',
      imageUrl: _img('photo-1519741497674-611481863552'),
      price: 2999,
      durationMin: 90,
      exclusiveGroup: 'bridal',
    ),
  ];
}
