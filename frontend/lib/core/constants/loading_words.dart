class LoadingWords {
  LoadingWords._();

  static const List<String> words = [
    'Cooking',
    'Brewing',
    'Bamboozling',
    'Crafting',
    'Thinking',
    'Hustling',
    'Calculating',
    'Figuring',
    'Conjuring',
    'Processing',
    'Scheming',
    'Pondering',
    'Contemplating',
    'Manifesting',
    'Engineering',
    'Vibing',
    'Decoding',
    'Untangling',
    'Simulating',
    'Philosophizing',
    'Hallucinating',
    'Overclocking',
    'Caffeinating',
    'Debugging',
    'Inventing',
    'Synthesizing',
    'Hypothesizing',
    'Daydreaming',
    'Theorizing',
    'Reverse engineering',
    'Brainstorming',
    'Speculating',
    'Innovating',
    'Deducing',
    'Encrypting',
    'Wrangling',
    'Summoning',
    'Architecting',
    'Channeling',
    'Defragmenting',
  ];

  static String getWord(int index) {
    return words[index % words.length];
  }
}
