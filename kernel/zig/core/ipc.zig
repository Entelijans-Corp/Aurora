const std = @import("std");

pub const max_message_bytes: usize = 64;

pub const Message = struct {
    sender_process_id: u32,
    len: u8,
    body: [max_message_bytes]u8 = [_]u8{0} ** max_message_bytes,

    pub fn init(sender_process_id: u32, text: []const u8) !Message {
        if (text.len > max_message_bytes) {
            return error.MessageTooLarge;
        }

        var message = Message{
            .sender_process_id = sender_process_id,
            .len = @intCast(text.len),
        };
        std.mem.copyForwards(u8, message.body[0..text.len], text);
        return message;
    }

    pub fn text(self: *const Message) []const u8 {
        return self.body[0..self.len];
    }
};

pub const Endpoint = struct {
    object_id: u32,
    queue: std.ArrayListUnmanaged(Message) = .{},

    pub fn init(object_id: u32) Endpoint {
        return .{ .object_id = object_id };
    }

    pub fn deinit(self: *Endpoint, allocator: std.mem.Allocator) void {
        self.queue.deinit(allocator);
    }

    pub fn send(self: *Endpoint, allocator: std.mem.Allocator, sender_process_id: u32, text: []const u8) !void {
        try self.queue.append(allocator, try Message.init(sender_process_id, text));
    }

    pub fn receive(self: *Endpoint) ?Message {
        if (self.queue.items.len == 0) {
            return null;
        }
        return self.queue.orderedRemove(0);
    }

    pub fn queued(self: *const Endpoint) usize {
        return self.queue.items.len;
    }
};

