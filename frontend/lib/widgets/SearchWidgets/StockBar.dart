import 'package:flutter/material.dart';
import 'package:frontend/models/customColors.dart';
import 'package:frontend/models/stocks.dart';
import 'package:frontend/services/flag_service.dart';

class StockBar extends StatelessWidget {
  final List<StockName> stocks;
  final int activeIndex;
  const StockBar({super.key, required this.stocks, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      width: double.infinity,
      child: Row(
        spacing: 3,
        children: stocks.indexed.map((entry) {
          final (index, stock) = entry;
          return Expanded(child: StockWidget(stock: stock, isActive: index == activeIndex));
        }).toList(),
      ),
    );
  }
}

class StockWidget extends StatelessWidget {
  final StockName stock;
  final bool isActive;
  StockWidget({super.key, required this.stock, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: !isActive ? CustomColors.primary : Color.fromARGB(255, 66, 72, 207),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Container(
              height: 24, 
              width: 24, 
              decoration: BoxDecoration(
                color: Colors.white,
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
                      child: Text(
                        stock.symbol[0],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                stock.symbol,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      )
    );
  }
}