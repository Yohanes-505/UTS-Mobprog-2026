import 'package:flutter/material.dart';


class InterestOptions {
  InterestOptions._();

  static const int minSelected = 3;
  static const int maxSelected = 8;

  static const Map<String, IconData> all = {
    'Traveling': Icons.flight_takeoff,
    'Musik': Icons.music_note,
    'Film': Icons.movie_outlined,
    'Kuliner': Icons.restaurant,
    'Ngopi': Icons.local_cafe_outlined,
    'Olahraga': Icons.sports_soccer,
    'Gym': Icons.fitness_center,
    'Gaming': Icons.sports_esports,
    'Membaca': Icons.menu_book_outlined,
    'Fotografi': Icons.camera_alt_outlined,
    'Memasak': Icons.soup_kitchen_outlined,
    'Hiking': Icons.terrain,
    'Seni': Icons.palette_outlined,
    'Teknologi': Icons.memory,
    'Hewan Peliharaan': Icons.pets,
    'Fashion': Icons.checkroom,
    'Menyanyi': Icons.mic_none,
    'Menari': Icons.nightlife,
    'Otomotif': Icons.directions_car_outlined,
    'Volunteering': Icons.volunteer_activism_outlined,
  };

  static List<String> get labels => all.keys.toList();

  static IconData iconFor(String label) => all[label] ?? Icons.tag;
}