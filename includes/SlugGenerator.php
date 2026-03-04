<?php
class SlugGenerator {
    private array $adjectives = [
        // Emotions & States
        'angry', 'sleepy', 'happy', 'grumpy', 'dizzy', 'lazy', 'crazy', 'silly',
        'funky', 'spicy', 'sassy', 'moody', 'gloomy', 'jumpy', 'nerdy', 'quirky',
        'sneaky', 'clumsy', 'bossy', 'fuzzy', 'groovy', 'loopy', 'wacky', 'zany',
        'cheeky', 'bouncy', 'fluffy', 'cranky', 'peppy', 'snappy', 'witty', 'jolly',
        'tipsy', 'feisty', 'frisky', 'giggly', 'wiggly', 'wobbly', 'bubbly', 'cuddly',
        
        // Appearance
        'tiny', 'giant', 'cosmic', 'sparkly', 'shiny', 'rusty', 'dusty', 'crusty',
        'golden', 'silver', 'purple', 'orange', 'crimson', 'azure', 'emerald',
        'invisible', 'glowing', 'dancing', 'flying', 'floating', 'spinning',
        'striped', 'spotted', 'polka', 'neon', 'rainbow', 'glittery', 'muddy',
        
        // Personality
        'brave', 'clever', 'wise', 'noble', 'royal', 'epic', 'legendary', 'mythic',
        'ancient', 'mystic', 'magic', 'cosmic', 'nuclear', 'atomic', 'turbo',
        'super', 'ultra', 'mega', 'hyper', 'quantum', 'cyber', 'techno', 'retro',
        
        // Weird & Funny
        'suspicious', 'confused', 'dramatic', 'chaotic', 'majestic', 'glorious',
        'magnificent', 'fabulous', 'fantastic', 'peculiar', 'bizarre', 'absurd',
        'random', 'awkward', 'tropical', 'arctic', 'volcanic', 'radioactive'
    ];

    private array $nouns = [
        // Food
        'potato', 'banana', 'pickle', 'taco', 'waffle', 'muffin', 'donut', 'pretzel',
        'burrito', 'nacho', 'noodle', 'pancake', 'cookie', 'cupcake', 'pizza',
        'avocado', 'coconut', 'mango', 'lemon', 'toast', 'bacon', 'cheese', 'nugget',
        
        // Animals
        'penguin', 'llama', 'alpaca', 'walrus', 'narwhal', 'platypus', 'sloth',
        'koala', 'panda', 'otter', 'hedgehog', 'raccoon', 'capybara', 'wombat',
        'flamingo', 'parrot', 'toucan', 'pelican', 'octopus', 'jellyfish', 'squid',
        'unicorn', 'dragon', 'phoenix', 'griffin', 'yeti', 'bigfoot', 'kraken',
        
        // People & Fantasy
        'wizard', 'ninja', 'pirate', 'viking', 'samurai', 'knight', 'jester',
        'goblin', 'troll', 'ogre', 'dwarf', 'giant', 'fairy', 'mermaid', 'centaur',
        'robot', 'cyborg', 'alien', 'zombie', 'vampire', 'ghost', 'skeleton',
        
        // Objects
        'potato', 'toaster', 'teapot', 'umbrella', 'cactus', 'mushroom', 'crystal',
        'rocket', 'spaceship', 'submarine', 'blimp', 'balloon', 'tornado', 'volcano',
        'boulder', 'pebble', 'asteroid', 'comet', 'nebula', 'galaxy', 'supernova',
        
        // Random Fun
        'tornado', 'tsunami', 'avalanche', 'earthquake', 'hurricane', 'blizzard',
        'disco', 'karaoke', 'fiesta', 'carnival', 'circus', 'safari', 'adventure'
    ];

    private PDO $pdo;

    public function __construct(PDO $pdo) {
        $this->pdo = $pdo;
    }

    public function generate(): string {
        $maxAttempts = 100;
        
        for ($i = 0; $i < $maxAttempts; $i++) {
            $adjective = $this->adjectives[array_rand($this->adjectives)];
            $noun = $this->nouns[array_rand($this->nouns)];
            $slug = $adjective . '-' . $noun;
            
            // Add number if basic combo exists
            if ($i > 10) {
                $slug .= '-' . random_int(1, 99);
            }
            
            if (!$this->slugExists($slug)) {
                return $slug;
            }
        }
        
        // Fallback: add timestamp
        return $this->adjectives[array_rand($this->adjectives)] . '-' . 
               $this->nouns[array_rand($this->nouns)] . '-' . 
               time();
    }

    private function slugExists(string $slug): bool {
        $stmt = $this->pdo->prepare("SELECT 1 FROM links WHERE slug = ?");
        $stmt->execute([$slug]);
        return (bool) $stmt->fetch();
    }

    public function getRandomMood(): string {
        $moods = [
            'feeling spicy today!',
            'in a funky mood!',
            'ready to party!',
            'vibing hard!',
            'on fire today!',
            'feeling legendary!',
            'being extra today!',
            'absolutely chaotic!',
            'unleashing creativity!',
            'in wizard mode!'
        ];
        return $moods[array_rand($moods)];
    }
}
