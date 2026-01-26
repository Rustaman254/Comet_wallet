import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../utils/responsive_utils.dart';

class OnboardingScreen1 extends StatelessWidget {
  final VoidCallback onNext;
  final int currentPage;

  const OnboardingScreen1({super.key, required this.onNext, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Main Illustration
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // White Board
                  Positioned(
                    child: Container(
                      width: 320.w,
                      height: 300.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: lightGreen, width: 2.w),
                      ),
                      child: Stack(
                        children: [
                          // Chart on left
                          Positioned(
                            left: 20,
                            top: 40,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Woman figure (simplified as icon)
                                Icon(Icons.person, size: 40.r, color: darkTeal),
                                SizedBox(height: 20.h),
                                // Bar chart
                                Row(
                                  children: [
                                    _buildBar(30.h, lightGreen),
                                    SizedBox(width: 8.w),
                                    _buildBar(50.h, lightGreen),
                                    SizedBox(width: 8.w),
                                    _buildBar(70.h, buttonGreen),
                                    SizedBox(width: 8.w),
                                    _buildBar(90.h, buttonGreen),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                // Line graph overlay
                                CustomPaint(
                                  size: Size(100.w, 30.h),
                                  painter: LineGraphPainter(),
                                ),
                              ],
                            ),
                          ),
                          // Progress indicators on right
                          Positioned(
                            right: 20,
                            top: 40,
                            child: Column(
                              children: [
                                _buildProgressCircle('90%', 0.9),
                                SizedBox(height: 20.h),
                                _buildProgressCircle('60%', 0.6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Money bag and coin
                  Positioned(
                    bottom: 20,
                    right: MediaQuery.of(context).size.width * 0.15,
                    child: Stack(
                      children: [
                        // Money bag
                        Container(
                          width: 60,
                          height: 70,
                          decoration: BoxDecoration(
                            color: buttonGreen,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30.r),
                              bottomRight: Radius.circular(30.r),
                              topLeft: Radius.circular(15.r),
                              topRight: Radius.circular(15.r),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Coin
                        Positioned(
                          left: -15,
                          top: 10,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: gold,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '\$',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Speech bubble
                  Positioned(
                    top: 20,
                    left: MediaQuery.of(context).size.width * 0.1,
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4.r,
                            height: 4.r,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Container(
                            width: 4.r,
                            height: 4.r,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Container(
                            width: 4.r,
                            height: 4.r,
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLiquidPageIndicator(0, currentPage),
                SizedBox(width: 8.w),
                _buildLiquidPageIndicator(1, currentPage),
                SizedBox(width: 8.w),
                _buildLiquidPageIndicator(2, currentPage),
              ],
            ),
            SizedBox(height: 30.h),
            // Text content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  Text(
                    'Welcome to Comet Wallet',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'A secure, smart way to manage your money every day.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            // Next button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 20.w,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }

  Widget _buildProgressCircle(String text, double progress) {
    return SizedBox(
      width: 60.r,
      height: 60.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60.r,
            height: 60.r,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4.w,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(buttonGreen),
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: buttonGreen,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidPageIndicator(int index, int currentPage) {
    final isActive = index == currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutBack,
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? buttonGreen : Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class LineGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lightGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width * 0.3, size.height * 0.7);
    path.lineTo(size.width * 0.6, size.height * 0.5);
    path.lineTo(size.width, size.height * 0.3);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingScreen2 extends StatelessWidget {
  final VoidCallback onNext;
  final int currentPage;

  const OnboardingScreen2({super.key, required this.onNext, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Main Illustration
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Male figure with trophy
                  Positioned(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy
                        Container(
                          width: 50,
                          height: 60,
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Figure with jacket
                        SizedBox(
                          width: 80,
                          height: 100,
                          child: Stack(
                            children: [
                              // Body
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  width: 80,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: darkGreen,
                                  ),
                                ),
                              ),
                              // Jacket overlay
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  width: 80,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: buttonGreen,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(40),
                                      bottomRight: Radius.circular(40),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Coins scattered around
                  Positioned(top: 100, left: 50, child: _buildCoinStack()),
                  Positioned(top: 120, right: 60, child: _buildCoinStack()),
                  Positioned(bottom: 100, left: 80, child: _buildCoinStack()),
                  Positioned(bottom: 80, right: 50, child: _buildCoinStack()),
                  // Dollar bills
                  Positioned(top: 150, left: 30, child: _buildDollarBill()),
                  Positioned(top: 160, right: 40, child: _buildDollarBill()),
                  // Leaves
                  Positioned(
                    bottom: 150,
                    left: 100,
                    child: Icon(Icons.eco, color: lightGreen, size: 20),
                  ),
                  Positioned(
                    bottom: 140,
                    right: 80,
                    child: Icon(Icons.eco, color: lightGreen, size: 20),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLiquidPageIndicator(0, currentPage),
                SizedBox(width: 8.w),
                _buildLiquidPageIndicator(1, currentPage),
                SizedBox(width: 8.w),
                _buildLiquidPageIndicator(2, currentPage),
              ],
            ),
            SizedBox(height: 30.h),
            // Text content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  Text(
                    'Clarity and Control',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Track spending, set budgets, and review every movement on an immutable ledger.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            // Next button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinStack() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '\$',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 2),
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _buildDollarBill() {
    return Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        color: buttonGreen,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Center(
        child: Text(
          '\$',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidPageIndicator(int index, int currentPage) {
    final isActive = index == currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutBack,
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? buttonGreen : Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingScreen3 extends StatelessWidget {
  final VoidCallback onNext;
  final int currentPage;

  const OnboardingScreen3({super.key, required this.onNext, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Main Illustration
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Browser window/document
                  Positioned(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.75,
                      height: MediaQuery.of(context).size.height * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: lightGreen, width: 2),
                      ),
                      child: Column(
                        children: [
                          // Browser header
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info, color: buttonGreen, size: 20),
                                SizedBox(width: 8.w),
                                Container(
                                  width: 120,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Pie chart segment
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CustomPaint(
                                size: const Size(100, 100),
                                painter: PieChartPainter(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Figure in green suit
                  Positioned(
                    right: MediaQuery.of(context).size.width * 0.1,
                    top: 50,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Head
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: darkGreen,
                          ),
                        ),
                        // Suit
                        Container(
                          width: 60,
                          height: 80,
                          decoration: BoxDecoration(
                            color: buttonGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Floating icons
                  Positioned(
                    top: 20,
                    left: 30,
                    child: _buildFloatingIcon(Icons.person, 'User'),
                  ),
                  Positioned(
                    top: 30,
                    right: 50,
                    child: _buildFloatingIcon(Icons.attach_money, 'Money'),
                  ),
                  Positioned(
                    bottom: 100,
                    left: 40,
                    child: _buildFloatingIcon(Icons.percent, 'Rate'),
                  ),
                  // Ledger/Data storage
                  Positioned(
                    bottom: 50,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDollarBill(),
                          SizedBox(width: 10),
                          _buildDollarBill(),
                        ],
                      ),
                    ),
                  ),
                  // Coins next to ledger
                  Positioned(
                    bottom: 40,
                    right: MediaQuery.of(context).size.width * 0.15,
                    child: Row(
                      children: [
                        _buildCoinStack(),
                        SizedBox(width: 5),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: gold,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLiquidPageIndicator(0, currentPage),
                SizedBox(width: 8.w),
                _buildLiquidPageIndicator(1, currentPage),
                SizedBox(width: 8.w),
                _buildLiquidPageIndicator(2, currentPage),
              ],
            ),
            SizedBox(height: 30.h),
            // Text content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  Text(
                    'Bank-grade Security',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Your balances and transactions are protected with strong encryption and audited ledgers.',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            // Next button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingIcon(IconData icon, String label) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: buttonGreen, size: 24),
    );
  }

  Widget _buildDollarBill() {
    return Container(
      width: 30,
      height: 40,
      decoration: BoxDecoration(
        color: buttonGreen,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          '\$',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCoinStack() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '\$',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 2),
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _buildLiquidPageIndicator(int index, int currentPage) {
    final isActive = index == currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutBack,
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? buttonGreen : Colors.grey[600],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = buttonGreen
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(
      rect,
      -1.57, // Start at top
      2.0, // 120 degrees
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
