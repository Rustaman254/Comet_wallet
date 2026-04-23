import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons/heroicons.dart';
import '../bloc/connectivity/connectivity_bloc.dart';
import '../bloc/connectivity/connectivity_event.dart';
import '../bloc/connectivity/connectivity_state.dart';
import '../constants/colors.dart';

class NoInternetOverlay extends StatelessWidget {
  const NoInternetOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, state) {
        if (state is ConnectivityOffline) {
          return Material(
            color: Colors.transparent,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
              width: double.infinity,
              height: double.infinity,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24.r),
                        decoration: BoxDecoration(
                          color: errorRed.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: HeroIcon(
                          HeroIcons.wifi,
                          size: 64.r,
                          color: errorRed,
                          style: HeroIconStyle.outline,
                        ),
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        'No Internet Connection',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: getTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Please check your network settings and try again. The app will resume automatically once connection is restored.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          color: getSecondaryTextColor(context),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 48.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<ConnectivityBloc>().add(const CheckConnectivity());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: getPrimaryBrandColor(),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Refresh Status',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
