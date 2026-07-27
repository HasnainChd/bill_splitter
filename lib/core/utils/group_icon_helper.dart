import 'package:flutter/material.dart';
import '../models/group.dart';

class GroupIconItem {
  final String title;
  final IconData icon;
  final String category;

  const GroupIconItem({
    required this.title,
    required this.icon,
    required this.category,
  });
}

class GroupIconHelper {
  // Curated list of all supported group icons grouped by category
  static const List<GroupIconItem> allIcons = [
    // Travel / Outings
    GroupIconItem(title: 'Flight', icon: Icons.flight_takeoff_rounded, category: 'Travel'),
    GroupIconItem(title: 'Road Trip', icon: Icons.directions_car_rounded, category: 'Travel'),
    GroupIconItem(title: 'Hotel', icon: Icons.hotel_rounded, category: 'Travel'),
    GroupIconItem(title: 'Cruises', icon: Icons.directions_boat_rounded, category: 'Travel'),
    GroupIconItem(title: 'Map / Tour', icon: Icons.map_rounded, category: 'Travel'),

    // Home / Rent
    GroupIconItem(title: 'Home', icon: Icons.home_rounded, category: 'Home'),
    GroupIconItem(title: 'Apartment', icon: Icons.apartment_rounded, category: 'Home'),
    GroupIconItem(title: 'Furniture', icon: Icons.weekend_rounded, category: 'Home'),
    GroupIconItem(title: 'Utilities', icon: Icons.bolt_rounded, category: 'Home'),
    GroupIconItem(title: 'Water', icon: Icons.water_drop_rounded, category: 'Home'),

    // Food & Dining
    GroupIconItem(title: 'Pizza / Food', icon: Icons.local_pizza_rounded, category: 'Dining'),
    GroupIconItem(title: 'Restaurant', icon: Icons.restaurant_rounded, category: 'Dining'),
    GroupIconItem(title: 'Coffee', icon: Icons.local_cafe_rounded, category: 'Dining'),
    GroupIconItem(title: 'Drinks', icon: Icons.local_bar_rounded, category: 'Dining'),
    GroupIconItem(title: 'Grocery', icon: Icons.shopping_basket_rounded, category: 'Dining'),

    // Sports & Play
    GroupIconItem(title: 'Party', icon: Icons.celebration_rounded, category: 'Life'),
    GroupIconItem(title: 'Movie', icon: Icons.movie_creation_rounded, category: 'Life'),
    GroupIconItem(title: 'Gaming', icon: Icons.sports_esports_rounded, category: 'Life'),
    GroupIconItem(title: 'Football', icon: Icons.sports_soccer_rounded, category: 'Life'),
    GroupIconItem(title: 'Shopping', icon: Icons.shopping_bag_rounded, category: 'Life'),

    // General & Money
    GroupIconItem(title: 'Group', icon: Icons.group_rounded, category: 'General'),
    GroupIconItem(title: 'Cash', icon: Icons.payments_rounded, category: 'General'),
    GroupIconItem(title: 'Savings', icon: Icons.account_balance_rounded, category: 'General'),
    GroupIconItem(title: 'Work / Office', icon: Icons.work_rounded, category: 'General'),
  ];

  // Quick select icons shown in group creation
  static const List<GroupIconItem> quickSelectIcons = [
    GroupIconItem(title: 'Flight', icon: Icons.flight_takeoff_rounded, category: 'Travel'),
    GroupIconItem(title: 'Home', icon: Icons.home_rounded, category: 'Home'),
    GroupIconItem(title: 'Pizza', icon: Icons.local_pizza_rounded, category: 'Dining'),
    GroupIconItem(title: 'Party', icon: Icons.celebration_rounded, category: 'Life'),
  ];

  static final Map<int, IconData> _codePointToIcon = Map.fromEntries(
    allIcons.map((item) => MapEntry(item.icon.codePoint, item.icon)),
  );

  /// Safe icon lookup — returns const IconData from predefined list, never constructs dynamic IconData
  static IconData getIconFromCodePoint(int codePoint,
      {IconData fallback = Icons.group_rounded}) {
    return _codePointToIcon[codePoint] ?? fallback;
  }

  // Parses raw group name to get clean group name
  static String getCleanGroupName(String rawName) {
    final match = RegExp(r'^(.*?)\s*\[icon:(\d+)\]\s*$').firstMatch(rawName);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return rawName.trim();
  }

  // Gets correct IconData, prioritizing database columns iconCodePoint and iconFontFamily
  static IconData getIconForGroup(Group group) {
    if (group.iconCodePoint != null) {
      return getIconFromCodePoint(
        group.iconCodePoint!,
        fallback: Icons.group_rounded,
      );
    }
    return getGroupIcon(group.name);
  }

  // Parses raw group name and returns correct IconData
  static IconData getGroupIcon(String rawName) {
    final match = RegExp(r'^(.*?)\s*\[icon:(\d+)\]\s*$').firstMatch(rawName);
    if (match != null) {
      final codePoint = int.tryParse(match.group(2)!);
      if (codePoint != null) {
        // Find icon in registry
        for (final item in allIcons) {
          if (item.icon.codePoint == codePoint) {
            return item.icon;
          }
        }
        // Fallback to safe icon lookup
        return getIconFromCodePoint(codePoint);
      }
    }

    // Heuristics based on name fallback
    final nameLower = rawName.toLowerCase();
    if (nameLower.contains('trip') ||
        nameLower.contains('travel') ||
        nameLower.contains('barcelona') ||
        nameLower.contains('tour') ||
        nameLower.contains('flight') ||
        nameLower.contains('vacation') ||
        nameLower.contains('road')) {
      return Icons.flight_takeoff_rounded;
    } else if (nameLower.contains('rent') ||
        nameLower.contains('home') ||
        nameLower.contains('apartment') ||
        nameLower.contains('flat') ||
        nameLower.contains('room') ||
        nameLower.contains('house') ||
        nameLower.contains('grove')) {
      return Icons.home_rounded;
    }
    return Icons.local_pizza_rounded;
  }

  // Appends icon code point tag to group name
  static String buildNameWithIcon(String cleanName, IconData icon) {
    return '$cleanName [icon:${icon.codePoint}]';
  }
}
