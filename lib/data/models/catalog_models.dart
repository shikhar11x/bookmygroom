class SalonBranch {
  const SalonBranch({required this.id, required this.name, required this.area});
  final String id;
  final String name;
  final String area;
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
  });
  final String id;
  final String name;
  final String imageUrl;
}

class Treatment {
  const Treatment({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.durationMin,
  });
  final String id;
  final String name;
  final String imageUrl;
  final int price; // INR
  final int durationMin;
}

class Stylist {
  const Stylist({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.experienceYears,
    required this.imageUrl,
  });
  final String id;
  final String name;
  final String role;
  final double rating;
  final int experienceYears;
  final String imageUrl;
}

class Offer {
  const Offer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.code,
  });
  final String id;
  final String title;
  final String subtitle;
  final String code;
}
