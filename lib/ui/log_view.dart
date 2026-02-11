import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/content_view_model.dart';

class LogView extends StatelessWidget {
  const LogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("日誌"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              context.read<ContentViewModel>().clearLog();
            },
          )
        ],
      ),
      body: SafeArea(
        child: Consumer<ContentViewModel>(
          builder: (context, vm, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              height: double.infinity,
              color: Colors.black87,
              child: SingleChildScrollView(
                reverse: true, // Auto scroll to bottom
                child: Text(
                  vm.log.isEmpty ? "尚無日誌" : vm.log,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
