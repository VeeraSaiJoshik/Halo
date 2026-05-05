import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/stocks.dart';
import 'package:frontend/services/flag_service.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';

class StockBar extends StatelessWidget {
  final List<StockName> stocks;
  final int activeIndex;
  final Function setIndex;
  final void Function(StockName stock, int index)? onStockTap;
  const StockBar({
    super.key,
    required this.stocks,
    required this.activeIndex,
    required this.setIndex,
    this.onStockTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      width: double.infinity,
      child: Row(
        spacing: 3,
        children: stocks.indexed.map((entry) {
          final (index, stock) = entry;
          return Expanded(
            child: StockWidget(
              stock: stock,
              isActive: index == activeIndex,
              onHover: (bool isActive) {
                if(isActive) setIndex(index);
              },
              onTap: onStockTap == null ? null : () => onStockTap!(stock, index),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StockWidget extends ConsumerWidget {
  final StockName stock;
  final bool isActive;
  final VoidCallback? onTap;
  final Function? onHover;
  StockWidget({super.key, required this.stock, required this.isActive, this.onTap, required this.onHover});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(haloThemeProvider);
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      onHover: onHover as Function(bool),
      borderRadius: BorderRadius.circular(5),
      child: AnimatedScale(
        duration: Duration(milliseconds: 250),
        curve: Curves.bounceInOut,
        scale: isActive ? 1.05 : 1,
        child: AnimatedRotation(
          curve: Curves.bounceInOut,
          duration: Duration(milliseconds: 250),
          turns: isActive ? -0.03 / (2 * 3.14) : 0,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: !isActive ? theme.primaryColor : theme.accentColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Container(
                  height: 24, 
                  width: 24, 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: EdgeInsets.all(1.5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      stock.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Color.fromARGB(255, 66, 72, 207),
                        child: Center(
                          child: Consumer(
                            builder: (context, ref, _) {
                              final theme = ref.watch(haloThemeProvider);
                              return Text(
                                stock.symbol[0],
                                style: theme.ticker,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final theme = ref.watch(haloThemeProvider);
                      return Text(
                        stock.symbol,
                        style: theme.ticker,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}