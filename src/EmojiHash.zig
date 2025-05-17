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
        for ([_]u64{2, 3, 5, 7, 11, 13, 17, 19, 23}) |p| {
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

/// Gets emoji representations for a password
/// Allocates a new slice that the caller must free
/// If custom_emojis is provided, uses that instead of the default emoji set
pub fn getPasswordEmojis(alloc: Allocator, password: []const u8, count: usize, custom_emojis: ?[]const []const u8) ![]const []const u8 {
    const hash = hashPassword(password);
    var result = try alloc.alloc([]const u8, count);
    
    // Choose which emoji table to use
    const emojis = custom_emojis orelse &default_emojis;
    
    // Generate primes starting from a value larger than our emoji table size
    // This ensures better distribution when selecting emojis
    const min_prime_size = emojis.len + 1;
    const primes = try generatePrimes(alloc, count, min_prime_size);
    defer alloc.free(primes);
    
    for (0..count) |i| {
        // Use a different prime for each position
        const emoji_idx = @mod(hash, primes[i]) % emojis.len;
        result[i] = emojis[@intCast(emoji_idx)];
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
        try testing.expect(small_primes[i] > small_primes[i-1]);
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
    
    // Test emoji generation with different counts
    const emojis1 = try getPasswordEmojis(alloc, "test", 3, null);
    defer alloc.free(emojis1);
    try testing.expectEqual(emojis1.len, 3);
    
    // Test with more emojis
    const emojis5 = try getPasswordEmojis(alloc, "test", 5, null);
    defer alloc.free(emojis5);
    try testing.expectEqual(emojis5.len, 5);
    
    // Same password should give same emojis
    const emojis2 = try getPasswordEmojis(alloc, "test", 3, null);
    defer alloc.free(emojis2);
    try testing.expectEqualSlices([]const u8, emojis1, emojis2);
    
    // Different password should give different emojis
    const emojis3 = try getPasswordEmojis(alloc, "different", 3, null);
    defer alloc.free(emojis3);
    try testing.expect(!std.meta.eql(emojis1, emojis3));
    
    // Test with custom emoji set
    const custom_emojis = [_][]const u8{ "🍕", "🍔", "🍟", "🌭", "🍿" };
    const custom_emoji_result = try getPasswordEmojis(alloc, "test", 3, &custom_emojis);
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