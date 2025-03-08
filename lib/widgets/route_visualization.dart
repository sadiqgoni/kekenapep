import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RouteVisualization extends StatelessWidget {
  final String source;
  final String destination;
  final List<String> landmarks;
  final bool isDetailed;

  const RouteVisualization({
    super.key,
    required this.source,
    required this.destination,
    required this.landmarks,
    this.isDetailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow[100]!, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildLocationDot(Colors.green[700]!, isStart: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  source,
                  style: GoogleFonts.poppins(
                    fontSize: isDetailed ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (landmarks.isNotEmpty) ...[
            for (int i = 0; i < landmarks.length; i++)
              _buildLandmarkItem(landmarks[i], i, landmarks.length),
          ],
          Row(
            children: [
              _buildLocationDot(Colors.red[700]!, isStart: false),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  destination,
                  style: GoogleFonts.poppins(
                    fontSize: isDetailed ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarkItem(String landmark, int index, int total) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 2,
              height: 20,
              color: Colors.yellow[700],
            ),
            _buildLocationDot(Colors.yellow[700]!, isLandmark: true),
            if (index < total - 1)
              Container(
                width: 2,
                height: 20,
                color: Colors.yellow[700],
              ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              landmark,
              style: GoogleFonts.poppins(
                fontSize: isDetailed ? 14 : 12,
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDot(Color color,
      {bool isStart = false, bool isLandmark = false}) {
    return Container(
      width: isLandmark ? 16 : 20,
      height: isLandmark ? 16 : 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: isLandmark
            ? null
            : Icon(
                isStart ? Icons.trip_origin : Icons.location_on,
                size: 12,
                color: color,
              ),
      ),
    );
  }
}

class DetailedRouteVisualization extends StatelessWidget {
  final String source;
  final String destination;
  final List<String> landmarks;
  final int? estimatedFare;

  const DetailedRouteVisualization({
    super.key,
    required this.source,
    required this.destination,
    required this.landmarks,
    this.estimatedFare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (estimatedFare != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated Fare',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₦$estimatedFare',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const Divider(),
            ],
            Text(
              'Route Details',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            RouteVisualization(
              source: source,
              destination: destination,
              landmarks: landmarks,
              isDetailed: true,
            ),
          ],
        ),
      ),
    );
  }
}
