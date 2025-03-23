// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String baseUrl = 'https://world.openfoodfacts.org/api/v2';

  Future<Map<String, dynamic>?> searchProductByName(String productName) async {
    try {
      // Search for products
      final searchResponse = await http.get(
        Uri.parse(
          'https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(productName)}&search_simple=1&action=process&json=1&page_size=5',
        ),
      );

      print('Search response status: ${searchResponse.statusCode}');

      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);

        if (searchData['products'] != null &&
            searchData['products'].isNotEmpty) {
          // Find the best match from results
          final products = searchData['products'] as List;
          Map<String, dynamic>? bestMatch;

          // Try to find a product whose name contains our search term
          for (var product in products) {
            final name =
                (product['product_name'] ?? '').toString().toLowerCase();
            if (name.contains(productName.toLowerCase())) {
              bestMatch = product;
              break;
            }
          }

          // Use the first product if no better match found
          final matchedProduct = bestMatch ?? products[0];
          print('Product found: ${matchedProduct['product_name']}');

          return matchedProduct;
        }
      }
      return null;
    } catch (e) {
      print('Error searching for product: $e');
      return null;
    }
  }

  double? extractSugarContent(Map<String, dynamic>? productData) {
    if (productData == null) return null;

    if (productData['nutriments'] != null &&
        productData['nutriments']['sugars_100g'] != null) {
      return productData['nutriments']['sugars_100g'].toDouble();
    }
    return null;
  }
}
