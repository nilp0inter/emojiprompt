const std = @import("std");
const Allocator = std.mem.Allocator;

/// Default list of emojis to use for password feedback - visually distinct with different colors and shapes
/// This can be overridden by the config file
const default_emojis = [_][]const u8{
    "🍎", "🍋", "🍉", "🍇", "🍊", "🍍", "🥝", "🍓", "🫐", "🍒", // Fruits - distinct colors
    "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", // Animals
    "🌍", "🌎", "🌏", "⭐", "🌙", "☀️", "⚡", "🔥", "❄️", "🌈", // Nature elements
    "🚗", "✈️", "🚂", "🚢", "🚁", "🚀", "🛸", "🏍️", "🚲", "🛵", // Vehicles
    "⚽", "🏀", "🏈", "⚾", "🎾", "🏐", "🏉", "🎱", "🏓", "🏒", // Sports
    "🎸", "🎻", "🎹", "🎺", "🥁", "🎷", "🪕", "🎤", "🎧", "📯", // Music
    "🏠", "🏢", "🏰", "⛪", "🏛️", "🏭", "🏗️", "🏖️", "🏔️", "🌋", // Places
    "💎", "🔑", "⏰", "📱", "💻", "🖨️", "📷", "📺", "🧰", "💡", // Objects
    "♠️", "♥️", "♦️", "♣️", "🔴", "🟠", "🟡", "🟢", "🔵", "🟣", // Symbols and colors
    "🥇", "🏆", "🧩", "🎲", "🎯", "🎨", "🎭", "🎪", "🎬", "🚩", // Activities
};

/// Fallback emoticons for terminals that don't support emojis
/// Uses classic ASCII emoticons that work everywhere
const fallback_emoticons = [_][]const u8{
    // Happy faces
    ":)",    ":-)",   ":D",     ":-D",   "=)",      "=D",      "^_^",      "^.^",   ":P",    ":-P",
    // Winking and playful
    ";)",    ";-)",   ";D",     ";P",    "8)",      "8-)",     "B)",       "B-)",   ":o)",   "(::",
    // Cool and neutral
    "8|",    ":|",    ":-|",    "=|",    "-_-",     "o_O",     "O_o",      "0_0",   "^o^",   "*_*",
    // Surprised and excited
    ":O",    ":-O",   ":o",     ":-o",   "=O",      "\\o/",    "\\o_o/",   "o.O",   "O.o",   ">:)",
    // Love and hearts
    "<3",    "</3",   ":*",     ":-*",   "=*",      ":x",      ":-x",      "xD",    "XD",    ":3",
    // Sad but still expressive
    ":(",    ":-(",   "=/",     ":-/",   ":\\",     ":-\\",    ">:(",      ">:-(",  "D:",    ":'(",
    // Silly and fun
    ":b",    ":-b",   ":p",     "xP",    "XP",      "=p",      "=P",       ">:P",   "<:)",   "]:)",
    // Misc expressions
    "o/",    "\\o",   "m(",     ")m",    "^5",      "o7",      "\\m/",     "m/",    "_o_",   "^u^",
    // More creative ones
    "(@_@)", "($.$)", "(&.&)",  "(#.#)", "(%.%)",   "(*.*)",   "(+.+)",    "(-.-)", "(=.=)", "(~.~)",
    // Action emoticons
    "\\m/",  "m/",    "_\\../", "\\../", "d(^.^)b", "b(^.^)d", "\\(^o^)/", "(^o^)", "(@.@)", "(o.o)",
};

/// Generate n prime numbers starting from min_prime or higher
/// Allocates a new slice that the caller must free
pub fn generatePrimes(alloc: Allocator, n: usize, min_prime: u64) ![]u64 {
    var primes = try alloc.alloc(u64, n);

    // Start with a candidate at least as large as min_prime
    var candidate: u64 = min_prime;

    // If candidate is even, make it odd (except for 2)
    if (candidate < 2) {
        candidate = 2;
    } else if (candidate == 2) {
        primes[0] = 2;
        if (n == 1) return primes;
        candidate = 3;
    } else if (candidate % 2 == 0) {
        candidate += 1;
    }

    var count: usize = 0;
    while (count < n) {
        var is_prime = true;

        // Check if candidate is divisible by any smaller number
        const sqrt_candidate = @as(u64, @intFromFloat(@sqrt(@as(f64, @floatFromInt(candidate)))));

        // For performance, first check against small prime factors
        for ([_]u64{ 2, 3, 5, 7, 11, 13, 17, 19, 23 }) |p| {
            if (candidate % p == 0 and candidate != p) {
                is_prime = false;
                break;
            }
        }

        // If it passes the quick check, do thorough check
        if (is_prime and candidate > 23) {
            var i: u64 = 29;
            while (i <= sqrt_candidate) : (i += 2) {
                if (candidate % i == 0) {
                    is_prime = false;
                    break;
                }
            }
        }

        if (is_prime) {
            primes[count] = candidate;
            count += 1;
        }

        // Skip even numbers (except for 2 which is already handled)
        if (candidate == 2) {
            candidate = 3;
        } else {
            candidate += 2;
        }
    }

    return primes;
}

/// Generates a hash value from a password string
pub fn hashPassword(password: []const u8) u64 {
    if (password.len == 0) return 0;

    var hash: u64 = 14695981039346656037; // FNV offset basis
    const prime: u64 = 1099511628211; // FNV prime

    // FNV-1a hash algorithm
    for (password) |c| {
        hash ^= c;
        hash = hash *% prime;
    }

    return hash;
}

/// Detects if the terminal supports emoji display
/// This is a heuristic based on environment variables
pub fn detectEmojiSupport() bool {
    // Check for known emoji-supporting terminals
    if (std.posix.getenv("TERM")) |term| {
        // Modern terminals that generally support emojis
        const emoji_terms = [_][]const u8{
            "xterm-256color",
            "screen-256color",
            "tmux-256color",
            "alacritty",
            "kitty",
            "wezterm",
            "gnome",
            "konsole",
        };

        for (emoji_terms) |emoji_term| {
            if (std.mem.indexOf(u8, term, emoji_term) != null) {
                return true;
            }
        }
    }

    // Check for UTF-8 locale support
    if (std.posix.getenv("LC_ALL")) |lc| {
        if (std.mem.indexOf(u8, lc, "UTF-8") != null or std.mem.indexOf(u8, lc, "utf8") != null) {
            return true;
        }
    }

    if (std.posix.getenv("LANG")) |lang| {
        if (std.mem.indexOf(u8, lang, "UTF-8") != null or std.mem.indexOf(u8, lang, "utf8") != null) {
            return true;
        }
    }

    // Conservative fallback - assume no emoji support
    return false;
}

/// Gets emoji representations for a password
/// Allocates a new slice that the caller must free
/// If custom_emojis is provided, uses that instead of the default emoji set
/// If show_real is false, returns decoy emojis that change during typing
pub fn getPasswordEmojis(alloc: Allocator, password: []const u8, count: usize, custom_emojis: ?[]const []const u8, show_real: bool) ![]const []const u8 {
    return getPasswordSymbols(alloc, password, count, custom_emojis, show_real, false, false);
}

/// Gets the maximum length of symbols in a symbol table
fn getMaxSymbolLength(symbols: []const []const u8) usize {
    var max_len: usize = 0;
    for (symbols) |symbol| {
        if (symbol.len > max_len) {
            max_len = symbol.len;
        }
    }
    return max_len;
}

/// Center-pads a symbol with spaces to match the target length
fn padSymbol(alloc: Allocator, symbol: []const u8, target_len: usize) ![]const u8 {
    if (symbol.len >= target_len) return alloc.dupe(u8, symbol);

    const padded = try alloc.alloc(u8, target_len);
    const padding_total = target_len - symbol.len;
    const padding_left = padding_total / 2;

    // Fill with spaces
    @memset(padded[0..padding_left], ' ');
    @memcpy(padded[padding_left .. padding_left + symbol.len], symbol);
    @memset(padded[padding_left + symbol.len ..], ' ');

    return padded;
}

/// Frees memory allocated by getPasswordSymbols
pub fn freePasswordSymbols(alloc: Allocator, symbols: []const []const u8, were_padded: bool) void {
    if (were_padded) {
        // Only free individual strings if they were padded (allocated)
        for (symbols) |symbol| {
            alloc.free(symbol);
        }
    }
    // Always free the main array
    alloc.free(symbols);
}

/// Gets password symbols (emojis or fallback symbols)
/// Allocates a new slice that the caller must free with freePasswordSymbols
/// If custom_emojis is provided, uses that instead of the default emoji set
/// If show_real is false, returns decoy symbols that change during typing
/// If use_fallback is true, uses ASCII-safe symbols instead of emojis
/// If pad_symbols is true, pads all symbols to the same length for consistent display
pub fn getPasswordSymbols(alloc: Allocator, password: []const u8, count: usize, custom_emojis: ?[]const []const u8, show_real: bool, use_fallback: bool, pad_symbols: bool) ![]const []const u8 {
    const base_hash = hashPassword(password);
    var result = try alloc.alloc([]const u8, count);

    // Choose which symbol table to use
    const symbols = if (use_fallback)
        // When using fallback mode, prefer custom emoticons if provided
        custom_emojis orelse &fallback_emoticons
    else
        // When using emoji mode, prefer custom emojis if provided
        custom_emojis orelse &default_emojis;

    const hash = if (show_real) base_hash else blk: {
        var prng = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
        break :blk prng.random().int(u64);
    };

    // Generate primes starting from a value larger than our symbol table size
    // This ensures better distribution when selecting symbols
    const min_prime_size = symbols.len + 1;
    const primes = try generatePrimes(alloc, count, min_prime_size);
    defer alloc.free(primes);

    // Get max symbol length if padding is requested
    const max_len = if (pad_symbols) getMaxSymbolLength(symbols) else 0;

    for (0..count) |i| {
        // Use a different prime for each position
        const symbol_idx = @mod(hash, primes[i]) % symbols.len;
        const selected_symbol = symbols[@intCast(symbol_idx)];

        if (pad_symbols and max_len > 0) {
            result[i] = try padSymbol(alloc, selected_symbol, max_len);
        } else {
            // Don't duplicate if not padding - just reference the original string
            result[i] = selected_symbol;
        }
    }

    return result;
}

test "prime generation" {
    const testing = std.testing;
    const alloc = testing.allocator;

    // Test generating small primes starting from 2
    const small_primes = try generatePrimes(alloc, 5, 2);
    defer alloc.free(small_primes);

    try testing.expectEqual(small_primes.len, 5);
    // The first value should be at least 2 (could be 2 or 3 depending on implementation)
    try testing.expect(small_primes[0] >= 2);

    // Verify each number is greater than the previous
    for (1..small_primes.len) |i| {
        try testing.expect(small_primes[i] > small_primes[i - 1]);
    }

    // Verify they're all prime
    for (small_primes) |p| {
        var is_prime = true;
        if (p > 2) {
            var div: u64 = 2;
            while (div * div <= p) : (div += 1) {
                if (p % div == 0) {
                    is_prime = false;
                    break;
                }
            }
        }
        try testing.expect(is_prime);
    }

    // Test generating primes starting from a higher value
    const primes_from_100 = try generatePrimes(alloc, 5, 100);
    defer alloc.free(primes_from_100);

    try testing.expectEqual(primes_from_100.len, 5);
    try testing.expect(primes_from_100[0] >= 100);
    try testing.expect(primes_from_100[1] > primes_from_100[0]);
    try testing.expect(primes_from_100[2] > primes_from_100[1]);
    try testing.expect(primes_from_100[3] > primes_from_100[2]);
    try testing.expect(primes_from_100[4] > primes_from_100[3]);

    // Check if they're actually prime
    for (primes_from_100) |p| {
        // Check if divisible by any number from 2 to sqrt(p)
        const sqrt_p = @as(u64, @intFromFloat(@sqrt(@as(f64, @floatFromInt(p)))));
        var is_prime = true;

        for (2..sqrt_p + 1) |i| {
            if (p % i == 0) {
                is_prime = false;
                break;
            }
        }

        try testing.expect(is_prime);
    }
}

test "emoji hash" {
    const testing = std.testing;
    const alloc = testing.allocator;

    // Test hash function gives consistent results
    try testing.expect(hashPassword("password123") == hashPassword("password123"));
    try testing.expect(hashPassword("abc") != hashPassword("def"));

    // Test emoji generation with different counts (real emojis)
    const emojis1 = try getPasswordEmojis(alloc, "test", 3, null, true);
    defer alloc.free(emojis1);
    try testing.expectEqual(emojis1.len, 3);

    // Test with more emojis
    const emojis5 = try getPasswordEmojis(alloc, "test", 5, null, true);
    defer alloc.free(emojis5);
    try testing.expectEqual(emojis5.len, 5);

    // Same password should give same emojis (real)
    const emojis2 = try getPasswordEmojis(alloc, "test", 3, null, true);
    defer alloc.free(emojis2);
    try testing.expectEqualSlices([]const u8, emojis1, emojis2);

    // Different password should give different emojis
    const emojis3 = try getPasswordEmojis(alloc, "different", 3, null, true);
    defer alloc.free(emojis3);
    try testing.expect(!std.meta.eql(emojis1, emojis3));

    // Test decoy vs real emojis - should be different (and random each time)
    const decoy_emojis1 = try getPasswordEmojis(alloc, "test", 3, null, false);
    defer alloc.free(decoy_emojis1);
    const decoy_emojis2 = try getPasswordEmojis(alloc, "test", 3, null, false);
    defer alloc.free(decoy_emojis2);

    // Decoy emojis should be different from real emojis
    try testing.expect(!std.meta.eql(emojis1, decoy_emojis1));
    // Decoy emojis should be random (different each time)
    try testing.expect(!std.meta.eql(decoy_emojis1, decoy_emojis2));

    // Test with custom emoji set
    const custom_emojis = [_][]const u8{ "🍕", "🍔", "🍟", "🌭", "🍿" };
    const custom_emoji_result = try getPasswordEmojis(alloc, "test", 3, &custom_emojis, true);
    defer alloc.free(custom_emoji_result);
    try testing.expectEqual(custom_emoji_result.len, 3);

    // Verify the custom emojis were used
    for (custom_emoji_result) |emoji| {
        var found = false;
        for (custom_emojis) |custom_emoji| {
            if (std.mem.eql(u8, emoji, custom_emoji)) {
                found = true;
                break;
            }
        }
        try testing.expect(found);
    }
}
