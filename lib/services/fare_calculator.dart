/// STEP 44: Centralized Fare Calculation Result for QuickRide Captain
class FareCalculationResult {
  final bool available;
  final double ratePerKm;
  final double fare;
  final String selectedSlab;
  final String? unavailableReason;

  const FareCalculationResult({
    required this.available,
    required this.ratePerKm,
    required this.fare,
    required this.selectedSlab,
    this.unavailableReason,
  });

  factory FareCalculationResult.unavailable({
    required String reason,
    String selectedSlab = 'None',
  }) {
    return FareCalculationResult(
      available: false,
      ratePerKm: 0.0,
      fare: 0.0,
      selectedSlab: selectedSlab,
      unavailableReason: reason,
    );
  }

  @override
  String toString() {
    return 'FareCalculationResult(available: $available, ratePerKm: $ratePerKm, fare: $fare, selectedSlab: $selectedSlab, unavailableReason: $unavailableReason)';
  }
}

/// Centralized fare calculation service for QuickRide Captain.
///
/// Implements Step 44 single-slab pricing rules:
/// - Bike: 1-50 km
/// - Auto: 1-50 km (Bike * 1.5)
/// - Car: 5-150 km (Bike * 2.5)
class FareCalculator {
  static FareCalculationResult calculate({
    required String vehicleType,
    required double distanceKm,
  }) {
    final vType = vehicleType.trim().toLowerCase();

    if (vType.contains('bike')) {
      return _calculateBikeFare(distanceKm);
    } else if (vType.contains('auto')) {
      return _calculateAutoFare(distanceKm);
    } else if (vType.contains('car')) {
      return _calculateCarFare(distanceKm);
    } else {
      return FareCalculationResult.unavailable(
        reason: 'Unsupported vehicle type: $vehicleType',
      );
    }
  }

  static FareCalculationResult _calculateBikeFare(double distance) {
    if (distance < 1.0) {
      return FareCalculationResult.unavailable(
        reason: 'Distance is below 1 km minimum for Bike.',
      );
    } else if (distance <= 5.0) {
      const rate = 8.00;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '1–5 km',
      );
    } else if (distance <= 10.0) {
      const rate = 5.50;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '5–10 km',
      );
    } else if (distance <= 20.0) {
      const rate = 4.50;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '10–20 km',
      );
    } else if (distance <= 35.0) {
      const rate = 4.00;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '20–35 km',
      );
    } else if (distance <= 50.0) {
      const rate = 3.50;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '35–50 km',
      );
    } else {
      return FareCalculationResult.unavailable(
        reason: 'Distance exceeds 50 km maximum for Bike.',
      );
    }
  }

  static FareCalculationResult _calculateAutoFare(double distance) {
    if (distance < 1.0) {
      return FareCalculationResult.unavailable(
        reason: 'Distance is below 1 km minimum for Auto.',
      );
    } else if (distance <= 5.0) {
      const rate = 12.00;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '1–5 km',
      );
    } else if (distance <= 10.0) {
      const rate = 8.25;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '5–10 km',
      );
    } else if (distance <= 20.0) {
      const rate = 6.75;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '10–20 km',
      );
    } else if (distance <= 35.0) {
      const rate = 6.00;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '20–35 km',
      );
    } else if (distance <= 50.0) {
      const rate = 5.25;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '35–50 km',
      );
    } else {
      return FareCalculationResult.unavailable(
        reason: 'Distance exceeds 50 km maximum for Auto.',
      );
    }
  }

  static FareCalculationResult _calculateCarFare(double distance) {
    if (distance < 5.0) {
      return FareCalculationResult.unavailable(
        reason: 'Distance is below 5 km minimum for Car.',
      );
    } else if (distance <= 10.0) {
      const rate = 13.75;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '5–10 km',
      );
    } else if (distance <= 20.0) {
      const rate = 11.25;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '10–20 km',
      );
    } else if (distance <= 35.0) {
      const rate = 10.00;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '20–35 km',
      );
    } else if (distance <= 150.0) {
      const rate = 8.75;
      return FareCalculationResult(
        available: true,
        ratePerKm: rate,
        fare: _round(distance * rate),
        selectedSlab: '35–150 km',
      );
    } else {
      return FareCalculationResult.unavailable(
        reason: 'Distance exceeds 150 km maximum for Car.',
      );
    }
  }

  static double _round(double val) {
    return (val * 100).roundToDouble() / 100.0;
  }
}
