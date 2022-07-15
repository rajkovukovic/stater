class JsonQueryMatcher {
  final Map<String, Function> matchersMap;

  const JsonQueryMatcher(this.matchersMap);

  Function? byCollectionName(String collectionName) =>
      matchersMap[collectionName];

  factory JsonQueryMatcher.empty() {
    return const JsonQueryMatcher({});
  }
}
