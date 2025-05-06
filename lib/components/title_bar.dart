import 'package:flutter/material.dart';

class TitleBar extends StatelessWidget {
  final VoidCallback onProfileTap;

  const TitleBar({
    Key? key,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120, // Height when fully expanded
      collapsedHeight: kToolbarHeight, // Set to toolbar height
      floating: false,
      pinned: false, // Set to false to allow the title bar to scroll away
      snap: false,
      automaticallyImplyLeading: false, // Disable the back arrow
      backgroundColor: Colors.white, // Ensures background is white
      surfaceTintColor: Colors.white, // Ensures no tint is applied
      shadowColor: Colors.transparent, // Removes shadow
      elevation: 0, // Removes elevation
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background
              Container(
                color: Colors.white,
              ),
              // Title Text
              Positioned(
                left: 24,
                bottom: 16,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome to\n',
                        style: TextStyle(
                          color: const Color(0xFF030303),
                          fontSize: 24, // Increased font size
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w700,
                          height: 1.33,
                        ),
                      ),
                      TextSpan(
                        text: 'MyChefAI!',
                        style: TextStyle(
                          color: const Color(0xFF030303),
                          fontSize: 32, // Increased font size
                          fontFamily: 'Quicksand',
                          fontWeight: FontWeight.w700,
                          height: 1.33,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Chef Guy Logo - aligned with the bottom of the MyChefAI text
              Positioned(
                right: 24,
                bottom: 16, // Match the bottom position of the title text
                child: Image.asset(
                  'assets/images/mychefai_guy.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
              // Profile Icon (Top Right)
              Positioned(
                right: 16,
                top: 16, // Align with the top of the screen
                child: Ink(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://assets.api.uizard.io/api/cdn/stream/30287e21-a052-451c-b549-d343df426b5f.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: InkWell(
                    splashColor: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                    onTap: onProfileTap, // Use the provided callback
                    child: Container(
                      width: 55,
                      height: 55,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}