/// Modèle pour les données de la wishlist
class WishlistData {
  final WishlistMeta? meta;
  final List<WishlistArticle> articles;

  WishlistData({
    this.meta,
    required this.articles,
  });

  factory WishlistData.fromJson(Map<String, dynamic> json) {
    return WishlistData(
      meta: json['meta'] != null 
          ? WishlistMeta.fromJson(json['meta']) 
          : null,
      articles: json['pivotArray'] != null
          ? (json['pivotArray'] as List)
              .map((article) => WishlistArticle.fromJson(article))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meta': meta?.toJson(),
      'pivotArray': articles.map((article) => article.toJson()).toList(),
    };
  }

  bool get isEmpty => articles.isEmpty;
  int get articleCount => articles.length;
}

/// Métadonnées de la wishlist
class WishlistMeta {
  final int? bestResultJirig;
  final double? totalPrice;
  final String? resultGainPerte;
  final int? totalArticles;

  WishlistMeta({
    this.bestResultJirig,
    this.totalPrice,
    this.resultGainPerte,
    this.totalArticles,
  });

  factory WishlistMeta.fromJson(Map<String, dynamic> json) {
    return WishlistMeta(
      bestResultJirig: json['iBestResultJirig'] as int?,
      totalPrice: _parseDouble(json['iTotalPriceArticleSelected']),
      resultGainPerte: json['sResultatGainPerte'] as String?,
      totalArticles: json['iTotalArticles'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'iBestResultJirig': bestResultJirig,
      'iTotalPriceArticleSelected': totalPrice,
      'sResultatGainPerte': resultGainPerte,
      'iTotalArticles': totalArticles,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Article de la wishlist
class WishlistArticle {
  final String code;
  final String? codeCrypt;
  final String? name;
  final String? description;
  final String? imageUrl;
  final int quantity;
  final double? price;
  final String? selectedCountry;
  final int? selectedCountryId;
  final Map<String, dynamic>? pricesByCountry;

  WishlistArticle({
    required this.code,
    this.codeCrypt,
    this.name,
    this.description,
    this.imageUrl,
    required this.quantity,
    this.price,
    this.selectedCountry,
    this.selectedCountryId,
    this.pricesByCountry,
  });

  factory WishlistArticle.fromJson(Map<String, dynamic> json) {
    return WishlistArticle(
      code: json['scodearticle'] ?? json['sCodeArticle'] ?? '',
      codeCrypt: json['sCodeArticleCrypt'] as String?,
      name: json['sname'] ?? json['sName'] as String?,
      description: json['sDescr'] as String?,
      imageUrl: json['sImage'] as String?,
      quantity: json['iqte'] ?? json['iQuantity'] ?? 1,
      price: _parseDouble(json['iPriceSelected']),
      selectedCountry: json['sPaysSelected'] as String?,
      selectedCountryId: json['iPaysSelected'] as int?,
      pricesByCountry: json['pricesByCountry'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scodearticle': code,
      'sCodeArticleCrypt': codeCrypt,
      'sname': name,
      'sDescr': description,
      'sImage': imageUrl,
      'iqte': quantity,
      'iPriceSelected': price,
      'sPaysSelected': selectedCountry,
      'iPaysSelected': selectedCountryId,
      'pricesByCountry': pricesByCountry,
    };
  }

  WishlistArticle copyWith({
    String? code,
    String? codeCrypt,
    String? name,
    String? description,
    String? imageUrl,
    int? quantity,
    double? price,
    String? selectedCountry,
    int? selectedCountryId,
    Map<String, dynamic>? pricesByCountry,
  }) {
    return WishlistArticle(
      code: code ?? this.code,
      codeCrypt: codeCrypt ?? this.codeCrypt,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedCountryId: selectedCountryId ?? this.selectedCountryId,
      pricesByCountry: pricesByCountry ?? this.pricesByCountry,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Modèle pour un panier (basket)
class Basket {
  final int id;
  final int localId;
  final String label;
  final int index;

  Basket({
    required this.id,
    required this.localId,
    required this.label,
    required this.index,
  });

  factory Basket.fromJson(Map<String, dynamic> json) {
    return Basket(
      id: json['iBasket'] ?? 0,
      localId: json['localId'] ?? 0,
      label: json['label'] ?? '',
      index: json['sIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'iBasket': id,
      'localId': localId,
      'label': label,
      'sIndex': index,
    };
  }
}

