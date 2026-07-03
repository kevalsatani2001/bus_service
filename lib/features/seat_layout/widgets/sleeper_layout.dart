import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A custom Sleeper Bus Seat Layout Widget.
/// Supports dual deck berths (Lower & Upper), 2x1 grid layout with central corridor,
/// seat status styling (Available, Booked, Selected), selection callback,
/// and smooth spring scale animations.
class SleeperLayout extends StatefulWidget {
  /// List of seat numbers that are already booked and disabled.
  final List<String> bookedSeats;

  /// Tenant primary theme color used for selected seats. Defaults to purple if null.
  final Color? themeColor;

  /// Callback triggered when an available seat is selected or deselected.
  final ValueChanged<String> onSeatSelected;

  const SleeperLayout({
    super.key,
    required this.bookedSeats,
    this.themeColor,
    required this.onSeatSelected,
  });

  @override
  State<SleeperLayout> createState() => _SleeperLayoutState();
}

class _SleeperLayoutState extends State<SleeperLayout> {
  final Set<String> _selectedSeats = {};

  Color get _primaryColor => widget.themeColor ?? Colors.indigo;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Berth Tab Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.chevronDown, size: 10),
                      SizedBox(width: 6),
                      Text('Lower Berth (નીચલો માળ)'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.chevronUp, size: 10),
                      SizedBox(width: 6),
                      Text('Upper Berth (ઉપલો માળ)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Legend Indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Available', Colors.white, Colors.grey.shade300, Colors.grey.shade700),
                _buildLegendItem('Selected', _primaryColor, _primaryColor, _primaryColor),
                _buildLegendItem('Booked', Colors.grey.shade200, Colors.grey.shade300, Colors.grey.shade600),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Bus Cabin Frame and Seats Scroll View
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Container(
                  width: 340,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Bus Front / Cockpit area
                      _buildBusCockpit(),

                      // Berth Grids inside TabBarView
                      SizedBox(
                        height: 480,
                        child: TabBarView(
                          children: [
                            _buildBerthGrid('L'), // Lower Berth (Prefix L)
                            _buildBerthGrid('U'), // Upper Berth (Prefix U)
                          ],
                        ),
                      ),

                      // Rear of Bus indicator
                      _buildBusRear(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color fill, Color border, Color textCol) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 16,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildBusCockpit() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 2)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.doorOpen, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Entrance',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Driver',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              FaIcon(FontAwesomeIcons.circleNotch, size: 20, color: Colors.grey), // steering wheel mock
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusRear() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      ),
      child: Center(
        child: Text(
          'REAR OF BUS',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildBerthGrid(String prefix) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 columns total (Left Double, Corridor, Right Single)
          crossAxisSpacing: 10,
          mainAxisSpacing: 16,
          childAspectRatio: 0.55, // Elongated sleeper sofa look
        ),
        itemCount: 20, // 5 rows * 4 columns = 20 grid spaces
        itemBuilder: (context, index) {
          final row = index ~/ 4;
          final col = index % 4;

          // Column 2 is the walkthrough corridor
          if (col == 2) {
            return const SizedBox.shrink();
          }

          int seatNumber;
          if (col < 2) {
            seatNumber = (row * 3) + col + 1;
          } else {
            seatNumber = (row * 3) + 3;
          }

          final seatLabel = '$prefix$seatNumber';
          final isBooked = widget.bookedSeats.contains(seatLabel);
          final isSelected = _selectedSeats.contains(seatLabel);

          return _SleeperSeatWidget(
            label: seatLabel,
            isBooked: isBooked,
            isSelected: isSelected,
            themeColor: _primaryColor,
            onTap: () {
              if (!isBooked) {
                setState(() {
                  if (_selectedSeats.contains(seatLabel)) {
                    _selectedSeats.remove(seatLabel);
                  } else {
                    _selectedSeats.add(seatLabel);
                  }
                });
                widget.onSeatSelected(seatLabel);
              }
            },
          );
        },
      ),
    );
  }
}

class _SleeperSeatWidget extends StatefulWidget {
  final String label;
  final bool isBooked;
  final bool isSelected;
  final Color themeColor;
  final VoidCallback onTap;

  const _SleeperSeatWidget({
    required this.label,
    required this.isBooked,
    required this.isSelected,
    required this.themeColor,
    required this.onTap,
  });

  @override
  State<_SleeperSeatWidget> createState() => _SleeperSeatWidgetState();
}

class _SleeperSeatWidgetState extends State<_SleeperSeatWidget> {
  bool _isTapping = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color pillowColor;
    Color textColor;

    if (widget.isBooked) {
      backgroundColor = Colors.grey.shade200; // dull grey
      borderColor = Colors.grey.shade300;
      pillowColor = Colors.grey.shade400;
      textColor = Colors.grey.shade600;
    } else if (widget.isSelected) {
      backgroundColor = widget.themeColor; // Solid background of current Active Tenant Color
      borderColor = widget.themeColor;
      pillowColor = Colors.white.withOpacity(0.25);
      textColor = Colors.white;
    } else {
      backgroundColor = Colors.white;
      borderColor = Colors.grey.shade300;
      pillowColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    }

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isBooked) {
          setState(() => _isTapping = true);
        }
      },
      onTapUp: (_) {
        if (!widget.isBooked) {
          setState(() => _isTapping = false);
        }
      },
      onTapCancel: () {
        if (!widget.isBooked) {
          setState(() => _isTapping = false);
        }
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isTapping ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (widget.isSelected)
                BoxShadow(
                  color: widget.themeColor.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            children: [
              // Pillow/Headrest design
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 14,
                decoration: BoxDecoration(
                  color: pillowColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                ),
              ),
              // Body area with icon and label
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.bed,
                        size: 13,
                        color: widget.isBooked
                            ? Colors.grey.shade500
                            : widget.isSelected
                                ? Colors.white
                                : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
