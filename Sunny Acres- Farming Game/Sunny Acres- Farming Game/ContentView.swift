//
//  ContentView.swift
//  Sunny Acres
//
//  A farming game for iPhone (SwiftUI and iOS).
//  Plow land, plant crops, raise trees and animals, fill orders, level up,
//  and expand your farm. Your farm keeps growing while the app is closed.
//

import SwiftUI
import Combine
import UIKit

// MARK: - Theme and helpers

enum Hue {
    static let cream = Color(red: 1.00, green: 0.97, blue: 0.88)
    static let wood = Color(red: 0.40, green: 0.26, blue: 0.13)
    static let woodDark = Color(red: 0.28, green: 0.17, blue: 0.08)
    static let ink = Color(red: 0.25, green: 0.16, blue: 0.08)
    static let grassA = Color(red: 0.45, green: 0.80, blue: 0.33)
    static let grassB = Color(red: 0.40, green: 0.74, blue: 0.30)
    static let soil = Color(red: 0.55, green: 0.36, blue: 0.20)
    static let soilDark = Color(red: 0.43, green: 0.27, blue: 0.14)
    static let gold = Color(red: 1.00, green: 0.80, blue: 0.20)
    static let leaf = Color(red: 0.22, green: 0.62, blue: 0.28)
    static let sky = Color(red: 0.53, green: 0.81, blue: 0.98)
    static let berry = Color(red: 0.88, green: 0.22, blue: 0.30)
}

enum Buzz {
    private static var isOn: Bool {
        UserDefaults.standard.object(forKey: "hapticsOn") as? Bool ?? true
    }

    static func tap() {
        guard isOn else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard isOn else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard isOn else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

enum Fmt {
    static func time(_ seconds: Double) -> String {
        let s = max(0, Int(seconds.rounded(.up)))
        if s < 60 { return "\(s)s" }
        let m = s / 60
        if m < 60 {
            let r = s % 60
            return r == 0 ? "\(m)m" : "\(m)m \(r)s"
        }
        let h = m / 60
        let rm = m % 60
        return rm == 0 ? "\(h)h" : "\(h)h \(rm)m"
    }
}

struct FarmPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Catalog

enum ItemCategory: String, Codable, CaseIterable, Hashable {
    case crop
    case tree
    case animal
    case decor
}

struct GoodDef {
    let id: String
    let name: String
    let emoji: String
    let price: Int
}

struct ItemDef: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let tileEmoji: String
    let category: ItemCategory
    let cost: Int
    let seconds: Double
    let goodID: String
    let amount: Int
    let xp: Int
    let level: Int

    var detail: String {
        switch category {
        case .crop:
            let price = Catalog.good(goodID)?.price ?? 0
            return "Grows in \(Fmt.time(seconds)). Sells for \(price) coins"
        case .tree, .animal:
            let emoji = Catalog.good(goodID)?.emoji ?? ""
            return "Makes \(amount) \(emoji) every \(Fmt.time(seconds))"
        case .decor:
            return "Makes your farm prettier. +\(xp) XP"
        }
    }
}

enum Catalog {
    static let goods: [GoodDef] = [
        GoodDef(id: "wheat", name: "Wheat", emoji: "🌾", price: 9),
        GoodDef(id: "carrot", name: "Carrot", emoji: "🥕", price: 22),
        GoodDef(id: "potato", name: "Potato", emoji: "🥔", price: 38),
        GoodDef(id: "tomato", name: "Tomato", emoji: "🍅", price: 66),
        GoodDef(id: "corn", name: "Corn", emoji: "🌽", price: 115),
        GoodDef(id: "strawberry", name: "Strawberry", emoji: "🍓", price: 180),
        GoodDef(id: "pumpkin", name: "Pumpkin", emoji: "🎃", price: 310),
        GoodDef(id: "watermelon", name: "Watermelon", emoji: "🍉", price: 540),
        GoodDef(id: "apple", name: "Apple", emoji: "🍎", price: 14),
        GoodDef(id: "orange", name: "Orange", emoji: "🍊", price: 24),
        GoodDef(id: "cherry", name: "Cherry", emoji: "🍒", price: 40),
        GoodDef(id: "egg", name: "Egg", emoji: "🥚", price: 14),
        GoodDef(id: "milk", name: "Milk", emoji: "🥛", price: 40),
        GoodDef(id: "wool", name: "Wool", emoji: "🧶", price: 60),
        GoodDef(id: "honey", name: "Honey", emoji: "🍯", price: 100)
    ]

    static let items: [ItemDef] = [
        // Crops
        ItemDef(id: "wheat", name: "Wheat", emoji: "🌾", tileEmoji: "🌾", category: .crop, cost: 5, seconds: 15, goodID: "wheat", amount: 1, xp: 2, level: 1),
        ItemDef(id: "carrot", name: "Carrot", emoji: "🥕", tileEmoji: "🥕", category: .crop, cost: 12, seconds: 45, goodID: "carrot", amount: 1, xp: 4, level: 1),
        ItemDef(id: "potato", name: "Potato", emoji: "🥔", tileEmoji: "🥔", category: .crop, cost: 20, seconds: 90, goodID: "potato", amount: 1, xp: 7, level: 2),
        ItemDef(id: "tomato", name: "Tomato", emoji: "🍅", tileEmoji: "🍅", category: .crop, cost: 35, seconds: 180, goodID: "tomato", amount: 1, xp: 12, level: 3),
        ItemDef(id: "corn", name: "Corn", emoji: "🌽", tileEmoji: "🌽", category: .crop, cost: 60, seconds: 300, goodID: "corn", amount: 1, xp: 20, level: 4),
        ItemDef(id: "strawberry", name: "Strawberry", emoji: "🍓", tileEmoji: "🍓", category: .crop, cost: 90, seconds: 480, goodID: "strawberry", amount: 1, xp: 32, level: 5),
        ItemDef(id: "pumpkin", name: "Pumpkin", emoji: "🎃", tileEmoji: "🎃", category: .crop, cost: 150, seconds: 900, goodID: "pumpkin", amount: 1, xp: 55, level: 7),
        ItemDef(id: "watermelon", name: "Watermelon", emoji: "🍉", tileEmoji: "🍉", category: .crop, cost: 250, seconds: 1800, goodID: "watermelon", amount: 1, xp: 90, level: 9),
        // Trees
        ItemDef(id: "apple_tree", name: "Apple Tree", emoji: "🍎", tileEmoji: "🌳", category: .tree, cost: 300, seconds: 180, goodID: "apple", amount: 3, xp: 10, level: 3),
        ItemDef(id: "orange_tree", name: "Orange Tree", emoji: "🍊", tileEmoji: "🌳", category: .tree, cost: 600, seconds: 300, goodID: "orange", amount: 3, xp: 18, level: 5),
        ItemDef(id: "cherry_tree", name: "Cherry Tree", emoji: "🍒", tileEmoji: "🌳", category: .tree, cost: 1000, seconds: 480, goodID: "cherry", amount: 3, xp: 28, level: 7),
        // Animals
        ItemDef(id: "chicken", name: "Chicken", emoji: "🐔", tileEmoji: "🐔", category: .animal, cost: 150, seconds: 60, goodID: "egg", amount: 1, xp: 6, level: 2),
        ItemDef(id: "cow", name: "Cow", emoji: "🐄", tileEmoji: "🐄", category: .animal, cost: 500, seconds: 180, goodID: "milk", amount: 1, xp: 15, level: 4),
        ItemDef(id: "sheep", name: "Sheep", emoji: "🐑", tileEmoji: "🐑", category: .animal, cost: 800, seconds: 300, goodID: "wool", amount: 1, xp: 24, level: 6),
        ItemDef(id: "beehive", name: "Beehive", emoji: "🐝", tileEmoji: "🐝", category: .animal, cost: 1500, seconds: 600, goodID: "honey", amount: 1, xp: 40, level: 8),
        // Decorations
        ItemDef(id: "flowers", name: "Flower Bed", emoji: "🌷", tileEmoji: "🌷", category: .decor, cost: 30, seconds: 0, goodID: "", amount: 0, xp: 5, level: 1),
        ItemDef(id: "picnic", name: "Picnic Blanket", emoji: "🧺", tileEmoji: "🧺", category: .decor, cost: 80, seconds: 0, goodID: "", amount: 0, xp: 8, level: 2),
        ItemDef(id: "pond", name: "Duck Pond", emoji: "🦆", tileEmoji: "🦆", category: .decor, cost: 200, seconds: 0, goodID: "", amount: 0, xp: 12, level: 3),
        ItemDef(id: "tent", name: "Camping Tent", emoji: "⛺", tileEmoji: "⛺", category: .decor, cost: 250, seconds: 0, goodID: "", amount: 0, xp: 15, level: 4),
        ItemDef(id: "fountain", name: "Fountain", emoji: "⛲", tileEmoji: "⛲", category: .decor, cost: 400, seconds: 0, goodID: "", amount: 0, xp: 20, level: 5)
    ]

    static func item(_ id: String) -> ItemDef? {
        items.first { $0.id == id }
    }

    static func good(_ id: String) -> GoodDef? {
        goods.first { $0.id == id }
    }

    static func byCategory(_ category: ItemCategory) -> [ItemDef] {
        items.filter { $0.category == category }
    }
}

enum Levels {
    static let maxLevel = 50

    /// Total XP needed to reach a level.
    static func threshold(_ level: Int) -> Int {
        40 * (level - 1) * level
    }

    static func level(for xp: Int) -> Int {
        var l = 1
        while l < maxLevel && xp >= threshold(l + 1) {
            l += 1
        }
        return l
    }

    static func progress(for xp: Int) -> Double {
        let l = level(for: xp)
        if l >= maxLevel { return 1 }
        let lo = threshold(l)
        let hi = threshold(l + 1)
        return Double(xp - lo) / Double(hi - lo)
    }
}

// MARK: - Models

enum TileKind: String, Codable {
    case grass
    case plot
    case crop
    case tree
    case animal
    case decor
}

struct Tile: Codable, Equatable {
    var unlocked: Bool
    var kind: TileKind = .grass
    var itemID: String? = nil
    var startedAt: Date? = nil
    var readyAt: Date? = nil
}

struct Order: Codable, Identifiable {
    var id = UUID()
    var needs: [String: Int]
    var coins: Int
    var xp: Int
}

struct FarmState: Codable {
    var coins = 200
    var gems = 3
    var xp = 0
    var tiles: [Tile] = []
    var inventory: [String: Int] = [:]
    var orders: [Order] = []
    var lastDailyClaim: Date? = nil
    var streak = 0
    var totalHarvests = 0

    static func fresh() -> FarmState {
        var s = FarmState()
        let cols = FarmStore.cols
        for r in 0..<FarmStore.rows {
            for c in 0..<cols {
                let open = (2...5).contains(r) && (1...4).contains(c)
                s.tiles.append(Tile(unlocked: open))
            }
        }
        for (r, c) in [(3, 2), (3, 3), (4, 2), (4, 3)] {
            s.tiles[r * cols + c].kind = .plot
        }
        return s
    }
}

enum Tool: Equatable {
    case hand
    case plow
    case plant(String)
    case remove
    case place(String)
}

struct FloatEvent: Identifiable {
    let id = UUID()
    let index: Int
    let text: String
    let color: Color
}

struct LevelUpInfo: Identifiable {
    let id = UUID()
    let level: Int
    let coins: Int
    let gems: Int
    let unlocks: [ItemDef]
}

// MARK: - Store (all game logic)

final class FarmStore: ObservableObject {
    static let cols = 6
    static let rows = 8
    static let plowCost = 5
    private static let saveKey = "sunnyAcres.save.v1"

    @Published var state: FarmState {
        didSet { save() }
    }
    @Published var tool: Tool = .hand
    @Published var selected: Int? = nil
    @Published var toast: String? = nil
    @Published var floats: [FloatEvent] = []
    @Published var levelUp: LevelUpInfo? = nil
    @Published var pendingUnlock: Int? = nil

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.saveKey),
           let saved = try? JSONDecoder().decode(FarmState.self, from: data),
           saved.tiles.count == Self.cols * Self.rows {
            state = saved
        } else {
            state = FarmState.fresh()
        }
        fillOrders()
    }

    func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    // MARK: Derived

    var level: Int { Levels.level(for: state.xp) }

    var selectedInBottomHalf: Bool {
        guard let s = selected else { return false }
        return s / Self.cols >= Self.rows / 2
    }

    var inventoryValue: Int {
        var total = 0
        for (id, count) in state.inventory {
            total += count * (Catalog.good(id)?.price ?? 0)
        }
        return total
    }

    func isReady(_ tile: Tile, now: Date = Date()) -> Bool {
        guard let ready = tile.readyAt else { return false }
        switch tile.kind {
        case .crop, .tree, .animal:
            return now >= ready
        default:
            return false
        }
    }

    func readyIndices(now: Date) -> [Int] {
        state.tiles.indices.filter { isReady(state.tiles[$0], now: now) }
    }

    // MARK: Feedback

    func showToast(_ text: String) {
        toast = text
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if self?.toast == text { self?.toast = nil }
        }
    }

    func emit(_ text: String, at index: Int, color: Color = Color.white) {
        let event = FloatEvent(index: index, text: text, color: color)
        floats.append(event)
        let eventID = event.id
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            self?.floats.removeAll { $0.id == eventID }
        }
    }

    @discardableResult
    private func spend(_ amount: Int) -> Bool {
        guard state.coins >= amount else {
            if toast != "Not enough coins" { Buzz.warning() }
            showToast("Not enough coins")
            return false
        }
        state.coins -= amount
        return true
    }

    func addXP(_ amount: Int) {
        guard amount > 0 else { return }
        let before = level
        state.xp += amount
        let after = level
        if after > before {
            var coins = 0
            var gems = 0
            for l in (before + 1)...after {
                coins += 50 * l
                gems += (l % 5 == 0) ? 3 : 1
            }
            state.coins += coins
            state.gems += gems
            let unlocks = Catalog.items.filter { $0.level > before && $0.level <= after }
            levelUp = LevelUpInfo(level: after, coins: coins, gems: gems, unlocks: unlocks)
            Buzz.success()
        }
    }

    // MARK: Tool selection

    func selectSeed(_ id: String) {
        tool = .plant(id)
        selected = nil
    }

    func startPlacing(_ id: String) {
        tool = .place(id)
        selected = nil
    }

    // MARK: Acting on tiles

    private static func kind(for category: ItemCategory) -> TileKind {
        switch category {
        case .crop: return .crop
        case .tree: return .tree
        case .animal: return .animal
        case .decor: return .decor
        }
    }

    func act(on index: Int, firstTouch: Bool) {
        guard state.tiles.indices.contains(index) else { return }
        let tile = state.tiles[index]

        if !tile.unlocked {
            if firstTouch { requestUnlock(index) }
            return
        }

        switch tool {
        case .hand:
            if isReady(tile) {
                collectTile(index)
            } else if firstTouch {
                selected = (selected == index) ? nil : index
                Buzz.tap()
            }

        case .plow:
            guard tile.kind == .grass else { return }
            guard spend(Self.plowCost) else { return }
            state.tiles[index].kind = .plot
            Buzz.tap()
            emit("-\(Self.plowCost) 🪙", at: index)

        case .plant(let id):
            guard let item = Catalog.item(id) else { return }
            guard tile.kind == .plot else {
                if firstTouch {
                    showToast(tile.kind == .grass ? "Plow this tile first" : "That tile is busy")
                }
                return
            }
            guard level >= item.level else {
                showToast("\(item.name) unlocks at level \(item.level)")
                return
            }
            guard spend(item.cost) else { return }
            let now = Date()
            state.tiles[index].kind = .crop
            state.tiles[index].itemID = id
            state.tiles[index].startedAt = now
            state.tiles[index].readyAt = now.addingTimeInterval(item.seconds)
            addXP(1)
            Buzz.tap()
            emit("-\(item.cost) 🪙", at: index)

        case .remove:
            guard firstTouch else { return }
            removeTile(index)

        case .place(let id):
            guard firstTouch else { return }
            guard let item = Catalog.item(id) else { return }
            guard tile.kind == .grass else {
                showToast("Pick an empty grass tile")
                return
            }
            guard level >= item.level else {
                showToast("\(item.name) unlocks at level \(item.level)")
                tool = .hand
                return
            }
            guard spend(item.cost) else {
                tool = .hand
                return
            }
            let now = Date()
            state.tiles[index].kind = Self.kind(for: item.category)
            state.tiles[index].itemID = id
            if item.seconds > 0 {
                state.tiles[index].startedAt = now
                state.tiles[index].readyAt = now.addingTimeInterval(item.seconds)
            }
            addXP(item.xp)
            Buzz.success()
            emit("-\(item.cost) 🪙", at: index)
        }
    }

    func collectTile(_ index: Int) {
        guard state.tiles.indices.contains(index) else { return }
        let tile = state.tiles[index]
        guard let id = tile.itemID, let item = Catalog.item(id) else { return }
        let good = Catalog.good(item.goodID)
        state.inventory[item.goodID, default: 0] += item.amount
        state.totalHarvests += 1
        let now = Date()
        if tile.kind == .crop {
            state.tiles[index].kind = .plot
            state.tiles[index].itemID = nil
            state.tiles[index].startedAt = nil
            state.tiles[index].readyAt = nil
        } else {
            state.tiles[index].startedAt = now
            state.tiles[index].readyAt = now.addingTimeInterval(item.seconds)
        }
        addXP(item.xp)
        emit("+\(item.amount) \(good?.emoji ?? "")  +\(item.xp) XP", at: index, color: Hue.gold)
        if selected == index { selected = nil }
        Buzz.tap()
    }

    func collectAll(now: Date = Date()) {
        let ready = readyIndices(now: now)
        guard !ready.isEmpty else { return }
        for i in ready { collectTile(i) }
        Buzz.success()
    }

    func removeTile(_ index: Int) {
        guard state.tiles.indices.contains(index) else { return }
        let tile = state.tiles[index]
        switch tile.kind {
        case .grass:
            return
        case .plot:
            state.tiles[index] = Tile(unlocked: true)
        case .crop:
            state.tiles[index].kind = .plot
            state.tiles[index].itemID = nil
            state.tiles[index].startedAt = nil
            state.tiles[index].readyAt = nil
        case .tree, .animal, .decor:
            let cost = tile.itemID.flatMap { Catalog.item($0) }?.cost ?? 0
            let refund = cost / 4
            state.coins += refund
            state.tiles[index] = Tile(unlocked: true)
            if refund > 0 { emit("+\(refund) 🪙", at: index, color: Hue.gold) }
        }
        if selected == index { selected = nil }
        Buzz.tap()
    }

    // MARK: Speed up

    func speedUpCost(_ tile: Tile, now: Date = Date()) -> Int {
        guard let ready = tile.readyAt else { return 0 }
        let remaining = max(0, ready.timeIntervalSince(now))
        return max(1, Int((remaining / 300).rounded(.up)))
    }

    func speedUp(_ index: Int) {
        guard state.tiles.indices.contains(index) else { return }
        let tile = state.tiles[index]
        guard let ready = tile.readyAt, ready > Date() else { return }
        let cost = speedUpCost(tile)
        guard state.gems >= cost else {
            showToast("Not enough gems")
            Buzz.warning()
            return
        }
        state.gems -= cost
        state.tiles[index].readyAt = Date()
        Buzz.success()
    }

    // MARK: Land

    func unlockCost() -> Int {
        let open = state.tiles.filter { $0.unlocked }.count
        return max(60, 60 * (open - 14))
    }

    func canUnlock(_ index: Int) -> Bool {
        let cols = Self.cols
        let row = index / cols
        let col = index % cols
        let neighbors = [(row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)]
        for (r, c) in neighbors {
            guard r >= 0, r < Self.rows, c >= 0, c < cols else { continue }
            if state.tiles[r * cols + c].unlocked { return true }
        }
        return false
    }

    func requestUnlock(_ index: Int) {
        guard canUnlock(index) else {
            showToast("Expand next to your farm first")
            return
        }
        pendingUnlock = index
    }

    func confirmUnlock(_ index: Int) {
        pendingUnlock = nil
        guard state.tiles.indices.contains(index), !state.tiles[index].unlocked else { return }
        let cost = unlockCost()
        guard spend(cost) else { return }
        state.tiles[index].unlocked = true
        addXP(5)
        emit("New land!", at: index, color: Hue.gold)
        Buzz.success()
    }

    // MARK: Market

    func sell(_ goodID: String, count: Int) {
        guard let good = Catalog.good(goodID) else { return }
        let have = state.inventory[goodID, default: 0]
        let n = min(count, have)
        guard n > 0 else { return }
        let left = have - n
        state.inventory[goodID] = left > 0 ? left : nil
        state.coins += n * good.price
        Buzz.tap()
    }

    func sellEverything() {
        let total = inventoryValue
        guard total > 0 else { return }
        state.coins += total
        state.inventory.removeAll()
        Buzz.success()
        showToast("Sold everything for \(total) coins")
    }

    // MARK: Orders

    func fillOrders() {
        while state.orders.count < 3 {
            state.orders.append(makeOrder())
        }
    }

    private func makeOrder() -> Order {
        let ownedIDs = Set(state.tiles.compactMap { $0.itemID })
        let currentLevel = level
        let available = Catalog.goods.filter { good in
            Catalog.items.contains { item in
                item.goodID == good.id && ((item.category == .crop && item.level <= currentLevel) || ownedIDs.contains(item.id))
            }
        }
        let pool = available.isEmpty ? [Catalog.goods[0]] : available
        let kinds = Int.random(in: 1...min(3, pool.count))
        let chosen = Array(pool.shuffled().prefix(kinds))
        var needs: [String: Int] = [:]
        var value = 0
        for good in chosen {
            let maxCount = good.price < 30 ? 6 : (good.price < 100 ? 4 : 2)
            let n = Int.random(in: 1...maxCount)
            needs[good.id] = n
            value += n * good.price
        }
        let coins = Int(Double(value) * 1.5) + 10
        let xp = max(3, value / 6)
        return Order(needs: needs, coins: coins, xp: xp)
    }

    func canFulfil(_ order: Order) -> Bool {
        for (id, n) in order.needs {
            if state.inventory[id, default: 0] < n { return false }
        }
        return true
    }

    func fulfil(_ order: Order) {
        guard canFulfil(order) else {
            showToast("You need more goods")
            Buzz.warning()
            return
        }
        for (id, n) in order.needs {
            let left = state.inventory[id, default: 0] - n
            state.inventory[id] = left > 0 ? left : nil
        }
        state.coins += order.coins
        state.orders.removeAll { $0.id == order.id }
        addXP(order.xp)
        fillOrders()
        Buzz.success()
    }

    func skipOrder(_ order: Order) {
        state.orders.removeAll { $0.id == order.id }
        fillOrders()
        Buzz.tap()
    }

    // MARK: Daily gift

    var canClaimDaily: Bool {
        guard let last = state.lastDailyClaim else { return true }
        return !Calendar.current.isDateInToday(last)
    }

    var nextStreak: Int {
        guard let last = state.lastDailyClaim else { return 1 }
        if Calendar.current.isDateInToday(last) { return state.streak }
        if Calendar.current.isDateInYesterday(last) { return state.streak + 1 }
        return 1
    }

    func dailyReward(streak: Int) -> (coins: Int, gems: Int) {
        let coins = 100 + 50 * min(max(streak - 1, 0), 6)
        let gems = (streak % 7 == 0) ? 5 : 1
        return (coins, gems)
    }

    func claimDaily() {
        guard canClaimDaily else { return }
        let streak = nextStreak
        let reward = dailyReward(streak: streak)
        state.streak = streak
        state.lastDailyClaim = Date()
        state.coins += reward.coins
        state.gems += reward.gems
        Buzz.success()
        showToast("Daily gift: +\(reward.coins) coins and +\(reward.gems) gems")
    }

    // MARK: Reset

    func resetFarm() {
        state = FarmState.fresh()
        fillOrders()
        tool = .hand
        selected = nil
        levelUp = nil
        floats.removeAll()
    }
}

// MARK: - Small animated pieces

struct PulsingEmoji: View {
    let emoji: String
    let size: CGFloat
    @State private var big = false

    var body: some View {
        Text(emoji)
            .font(.system(size: size))
            .scaleEffect(big ? 1.08 : 0.94)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: big)
            .onAppear { big = true }
    }
}

struct ReadyBubble: View {
    let emoji: String
    let size: CGFloat
    @State private var up = false

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.24))
            .frame(width: size * 0.4, height: size * 0.4)
            .background(Circle().fill(Color.white))
            .overlay(Circle().stroke(Hue.gold, lineWidth: 2))
            .shadow(color: Color.black.opacity(0.25), radius: 2, y: 1)
            .offset(y: up ? -3 : 2)
            .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: up)
            .onAppear { up = true }
    }
}

struct MiniBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.35))
                Capsule().fill(Hue.gold).frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 5)
    }
}

struct FloatLabel: View {
    let text: String
    let color: Color
    @State private var go = false

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .shadow(color: Color.black.opacity(0.7), radius: 2, y: 1)
            .fixedSize()
            .offset(y: go ? -38 : 0)
            .opacity(go ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) { go = true }
            }
    }
}

// MARK: - Tile

struct TileView: View {
    let tile: Tile
    let index: Int
    let size: CGFloat
    let now: Date
    let isSelected: Bool
    let canExpand: Bool
    let expandCost: Int

    private var item: ItemDef? {
        guard let id = tile.itemID else { return nil }
        return Catalog.item(id)
    }

    private var isReady: Bool {
        guard let ready = tile.readyAt else { return false }
        return now >= ready
    }

    private var fraction: Double {
        guard let start = tile.startedAt, let ready = tile.readyAt else { return 1 }
        let total = ready.timeIntervalSince(start)
        guard total > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(start) / total))
    }

    private var productEmoji: String {
        guard let item else { return "⭐️" }
        return Catalog.good(item.goodID)?.emoji ?? "⭐️"
    }

    var body: some View {
        ZStack {
            background
            content
            if tile.kind == .animal {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Hue.wood.opacity(0.55), lineWidth: 2)
            }
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white, lineWidth: 3)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder private var background: some View {
        if !tile.unlocked {
            ZStack {
                Color(red: 0.19, green: 0.31, blue: 0.21)
                VStack(spacing: 1) {
                    Text(canExpand ? "➕" : "🔒").font(.system(size: size * 0.3))
                    if canExpand {
                        Text("\(expandCost)")
                            .font(.system(size: size * 0.2, weight: .heavy, design: .rounded))
                            .foregroundStyle(Hue.gold)
                    }
                }
                .opacity(canExpand ? 1 : 0.5)
            }
        } else if tile.kind == .plot || tile.kind == .crop {
            ZStack {
                Hue.soil
                VStack(spacing: size * 0.14) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(Hue.soilDark).frame(height: size * 0.07)
                    }
                }
                .padding(.horizontal, size * 0.1)
            }
        } else {
            ((index / FarmStore.cols + index % FarmStore.cols) % 2 == 0) ? Hue.grassA : Hue.grassB
        }
    }

    @ViewBuilder private var content: some View {
        switch tile.kind {
        case .grass, .plot:
            EmptyView()
        case .crop:
            if let item { cropContent(item) }
        case .tree:
            if item != nil { treeContent }
        case .animal:
            if let item { animalContent(item) }
        case .decor:
            if let item {
                Text(item.tileEmoji).font(.system(size: size * 0.66))
            }
        }
    }

    private func cropContent(_ item: ItemDef) -> some View {
        ZStack {
            if isReady {
                PulsingEmoji(emoji: item.emoji, size: size * 0.64)
            } else {
                Text(fraction < 0.5 ? "🌱" : "🌿")
                    .font(.system(size: size * (0.32 + 0.2 * fraction)))
                VStack {
                    Spacer()
                    MiniBar(fraction: fraction)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 4)
                }
            }
        }
    }

    private var treeContent: some View {
        ZStack {
            Text("🌳").font(.system(size: size * 0.74))
            if isReady {
                ReadyBubble(emoji: productEmoji, size: size)
                    .offset(x: size * 0.22, y: -size * 0.2)
            } else {
                VStack {
                    Spacer()
                    MiniBar(fraction: fraction)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 4)
                }
            }
        }
    }

    private func animalContent(_ item: ItemDef) -> some View {
        ZStack {
            Text(item.tileEmoji).font(.system(size: size * 0.6))
            if isReady {
                ReadyBubble(emoji: productEmoji, size: size)
                    .offset(x: size * 0.22, y: -size * 0.2)
            } else {
                VStack {
                    Spacer()
                    MiniBar(fraction: fraction)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 4)
                }
            }
        }
    }
}

// MARK: - Farm board

struct FarmBoard: View {
    @ObservedObject var store: FarmStore
    @State private var lastIndex: Int? = nil
    private let spacing: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            let cols = FarmStore.cols
            let rows = FarmStore.rows
            let tile = floor(min(
                (geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols),
                (geo.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            ))
            let gridW = tile * CGFloat(cols) + spacing * CGFloat(cols - 1)
            let gridH = tile * CGFloat(rows) + spacing * CGFloat(rows - 1)
            let step = tile + spacing
            let expandCost = store.unlockCost()

            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(spacing: spacing) {
                    ForEach(0..<rows, id: \.self) { r in
                        HStack(spacing: spacing) {
                            ForEach(0..<cols, id: \.self) { c in
                                let index = r * cols + c
                                let t = store.state.tiles[index]
                                TileView(
                                    tile: t,
                                    index: index,
                                    size: tile,
                                    now: context.date,
                                    isSelected: store.selected == index,
                                    canExpand: !t.unlocked && store.canUnlock(index),
                                    expandCost: expandCost
                                )
                            }
                        }
                    }
                }
                .overlay(alignment: .topLeading) {
                    ZStack(alignment: .topLeading) {
                        ForEach(store.floats) { event in
                            FloatLabel(text: event.text, color: event.color)
                                .position(
                                    x: CGFloat(event.index % cols) * step + tile / 2,
                                    y: CGFloat(event.index / cols) * step + tile / 2
                                )
                        }
                    }
                    .allowsHitTesting(false)
                }
            }
            .frame(width: gridW, height: gridH)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = value.location.x
                        let y = value.location.y
                        guard x >= 0, y >= 0 else { return }
                        let col = Int(x / step)
                        let row = Int(y / step)
                        guard col < cols, row < rows else { return }
                        let index = row * cols + col
                        if index != lastIndex {
                            let first = (lastIndex == nil)
                            lastIndex = index
                            store.act(on: index, firstTouch: first)
                        }
                    }
                    .onEnded { _ in
                        lastIndex = nil
                    }
            )
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - HUD

struct StatPill: View {
    let emoji: String
    let value: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji).font(.system(size: 16))
            Text("\(value)")
                .font(.system(.subheadline, design: .rounded, weight: .heavy))
                .monospacedDigit()
                .foregroundStyle(Color.white)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.black.opacity(0.3), in: Capsule())
        .animation(.easeOut(duration: 0.3), value: value)
    }
}

struct HUDView: View {
    @ObservedObject var store: FarmStore
    var onMenu: () -> Void

    var body: some View {
        let level = store.level
        let lo = Levels.threshold(level)
        let hi = Levels.threshold(level + 1)
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.black.opacity(0.3))
                Circle().stroke(Color.white.opacity(0.25), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: Levels.progress(for: store.state.xp))
                    .stroke(Hue.gold, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(level)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 1) {
                Text("Level \(level)")
                    .font(.system(.footnote, design: .rounded, weight: .heavy))
                Text("\(store.state.xp - lo)/\(hi - lo) XP")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .opacity(0.85)
            }
            .foregroundStyle(Color.white)
            .shadow(color: Color.black.opacity(0.35), radius: 2, y: 1)

            Spacer(minLength: 4)

            StatPill(emoji: "🪙", value: store.state.coins)
            StatPill(emoji: "💎", value: store.state.gems)

            Button {
                Buzz.tap()
                onMenu()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.3), in: Circle())
                    .overlay(alignment: .topTrailing) {
                        if store.canClaimDaily {
                            Circle().fill(Hue.berry).frame(width: 12, height: 12)
                        }
                    }
            }
            .buttonStyle(FarmPressStyle())
        }
    }
}

// MARK: - Hint bar and tile info card

struct HintBar: View {
    @ObservedObject var store: FarmStore
    let now: Date

    private var hint: String {
        switch store.tool {
        case .hand:
            if store.state.totalHarvests == 0 {
                return "Tap the seed bag, pick Wheat, then drag over the brown soil."
            }
            return "Tap ripe crops to harvest. Drag to sweep many."
        case .plow:
            return "Drag over grass to plow soil (\(FarmStore.plowCost) coins each)."
        case .plant(let id):
            let item = Catalog.item(id)
            return "Drag over soil to plant \(item?.name ?? "seeds") (\(item?.cost ?? 0) coins)."
        case .remove:
            return "Tap something to remove it."
        case .place(let id):
            let item = Catalog.item(id)
            return "Tap empty grass to place \(item?.name ?? "item") (\(item?.cost ?? 0) coins)."
        }
    }

    var body: some View {
        let ready = store.readyIndices(now: now).count
        HStack(spacing: 8) {
            Text(hint)
                .font(.system(.footnote, design: .rounded, weight: .bold))
                .foregroundStyle(Color.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            if store.tool != .hand {
                Button {
                    Buzz.tap()
                    store.tool = .hand
                } label: {
                    Text("Done")
                        .font(.system(.footnote, design: .rounded, weight: .heavy))
                        .foregroundStyle(Hue.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white, in: Capsule())
                }
                .buttonStyle(FarmPressStyle())
            }
            if ready > 0 {
                Button {
                    store.collectAll()
                } label: {
                    Text("Collect all (\(ready))")
                        .font(.system(.footnote, design: .rounded, weight: .heavy))
                        .foregroundStyle(Hue.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Hue.gold, in: Capsule())
                }
                .buttonStyle(FarmPressStyle())
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct InfoButton: View {
    let title: String
    let icon: String
    var prominent = false
    let action: () -> Void

    var body: some View {
        Button {
            Buzz.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                Text(icon)
                Text(title).font(.system(.subheadline, design: .rounded, weight: .heavy))
            }
            .foregroundStyle(prominent ? Color.white : Hue.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(prominent ? Hue.leaf : Hue.ink.opacity(0.1), in: Capsule())
        }
        .buttonStyle(FarmPressStyle())
    }
}

struct TileInfoCard: View {
    @ObservedObject var store: FarmStore
    let index: Int
    let now: Date
    var onChooseSeeds: () -> Void

    private var tile: Tile { store.state.tiles[index] }

    private var item: ItemDef? {
        guard let id = tile.itemID else { return nil }
        return Catalog.item(id)
    }

    private var isReady: Bool {
        guard let ready = tile.readyAt else { return false }
        return now >= ready
    }

    private var remaining: Double {
        max(0, (tile.readyAt ?? now).timeIntervalSince(now))
    }

    private var fraction: Double {
        guard let start = tile.startedAt, let ready = tile.readyAt else { return 1 }
        let total = ready.timeIntervalSince(start)
        guard total > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(start) / total))
    }

    private var header: (emoji: String, title: String, subtitle: String) {
        switch tile.kind {
        case .grass:
            return ("🌿", "Empty grass", "Plow it to make soil for crops.")
        case .plot:
            return ("🟫", "Fertile soil", "Ready for seeds.")
        default:
            if let item { return (item.tileEmoji, item.name, item.detail) }
            return ("🌿", "Farm tile", "")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(header.emoji).font(.system(size: 36))
                VStack(alignment: .leading, spacing: 2) {
                    Text(header.title)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Hue.ink)
                    Text(header.subtitle)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(Hue.ink.opacity(0.7))
                }
                Spacer()
                Button {
                    store.selected = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Hue.ink.opacity(0.4))
                }
            }

            if tile.kind == .crop || tile.kind == .tree || tile.kind == .animal {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Hue.ink.opacity(0.12))
                            Capsule()
                                .fill(Hue.leaf)
                                .frame(width: geo.size.width * (isReady ? 1 : fraction))
                        }
                    }
                    .frame(height: 10)
                    Text(isReady ? "Ready to collect!" : "Ready in \(Fmt.time(remaining))")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(Hue.ink.opacity(0.75))
                }
            }

            actions
        }
        .padding(14)
        .background(Hue.cream, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 4)
    }

    @ViewBuilder private var actions: some View {
        switch tile.kind {
        case .grass:
            InfoButton(title: "Plow (\(FarmStore.plowCost) coins)", icon: "🚜", prominent: true) {
                store.tool = .plow
                store.selected = nil
            }
        case .plot:
            InfoButton(title: "Choose seeds", icon: "🌱", prominent: true) {
                store.selected = nil
                onChooseSeeds()
            }
        case .crop, .tree, .animal:
            HStack(spacing: 8) {
                if isReady {
                    InfoButton(title: "Collect", icon: "🧺", prominent: true) {
                        store.collectTile(index)
                    }
                } else {
                    InfoButton(title: "Speed up \(store.speedUpCost(tile, now: now))", icon: "💎", prominent: true) {
                        store.speedUp(index)
                    }
                }
                InfoButton(title: tile.kind == .crop ? "Remove" : "Sell back", icon: "🗑️") {
                    store.removeTile(index)
                }
            }
        case .decor:
            InfoButton(title: "Sell back", icon: "🗑️") {
                store.removeTile(index)
            }
        }
    }
}

// MARK: - Dock

struct DockButton: View {
    let emoji: String
    let label: String
    var active = false
    var badge = false
    let action: () -> Void

    var body: some View {
        Button {
            Buzz.tap()
            action()
        } label: {
            VStack(spacing: 2) {
                Text(emoji).font(.system(size: 24))
                Text(label).font(.system(size: 10, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Color.white)
            .frame(width: 46, height: 54)
            .background(
                active ? Color.white.opacity(0.28) : Color.clear,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(alignment: .topTrailing) {
                if badge {
                    Circle().fill(Hue.berry).frame(width: 11, height: 11).offset(x: -3, y: 3)
                }
            }
        }
        .buttonStyle(FarmPressStyle())
    }
}

enum FarmSheet: String, Identifiable {
    case shop
    case seeds
    case barn
    case orders
    case menu

    var id: String { rawValue }
}

struct DockView: View {
    @ObservedObject var store: FarmStore
    var openSheet: (FarmSheet) -> Void

    private var seedIcon: String {
        if case .plant(let id) = store.tool, let item = Catalog.item(id) {
            return item.emoji
        }
        return "🌱"
    }

    private var plantActive: Bool {
        if case .plant = store.tool { return true }
        return false
    }

    var body: some View {
        HStack(spacing: 2) {
            DockButton(emoji: "✋", label: "Hand", active: store.tool == .hand) {
                store.tool = .hand
            }
            DockButton(emoji: "🚜", label: "Plow", active: store.tool == .plow) {
                store.selected = nil
                store.tool = .plow
            }
            DockButton(emoji: seedIcon, label: "Seeds", active: plantActive) {
                openSheet(.seeds)
            }
            DockButton(emoji: "🗑️", label: "Remove", active: store.tool == .remove) {
                store.selected = nil
                store.tool = .remove
            }

            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(width: 1, height: 36)
                .padding(.horizontal, 4)

            DockButton(emoji: "🏪", label: "Shop") { openSheet(.shop) }
            DockButton(emoji: "🏚️", label: "Barn") { openSheet(.barn) }
            DockButton(
                emoji: "📋",
                label: "Orders",
                badge: store.state.orders.contains { store.canFulfil($0) }
            ) {
                openSheet(.orders)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(Hue.woodDark.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: - Sheets

struct SheetShell<Content: View>: View {
    let title: String
    let onClose: () -> Void
    let content: Content

    init(title: String, onClose: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        ZStack {
            Hue.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(Hue.ink)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Hue.wood.opacity(0.55))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                content
            }
        }
    }
}

struct ItemRow: View {
    let item: ItemDef
    let unlocked: Bool
    let affordable: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Buzz.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                Text(item.emoji)
                    .font(.system(size: 34))
                    .frame(width: 54, height: 54)
                    .background(Hue.grassA.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Hue.ink)
                    Text(item.detail)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(Hue.ink.opacity(0.7))
                        .multilineTextAlignment(.leading)
                    Text("+\(item.xp) XP")
                        .font(.system(.caption2, design: .rounded, weight: .heavy))
                        .foregroundStyle(Hue.leaf)
                }
                Spacer(minLength: 6)
                if unlocked {
                    Text("🪙 \(item.cost)")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(affordable ? Hue.ink : Hue.berry)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Hue.gold.opacity(0.35), in: Capsule())
                } else {
                    VStack(spacing: 0) {
                        Text("🔒")
                        Text("Lv \(item.level)")
                            .font(.system(.caption, design: .rounded, weight: .heavy))
                    }
                    .foregroundStyle(Hue.ink.opacity(0.6))
                }
            }
            .padding(12)
            .background(Color.white.opacity(unlocked ? 0.85 : 0.5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .opacity(unlocked ? 1 : 0.7)
        }
        .buttonStyle(FarmPressStyle())
        .disabled(!unlocked)
    }
}

struct ShopSheet: View {
    @ObservedObject var store: FarmStore
    let onClose: () -> Void
    @State private var category: ItemCategory = .tree

    var body: some View {
        SheetShell(title: "Farm Shop", onClose: onClose) {
            VStack(spacing: 10) {
                Picker("Category", selection: $category) {
                    Text("Trees").tag(ItemCategory.tree)
                    Text("Animals").tag(ItemCategory.animal)
                    Text("Decor").tag(ItemCategory.decor)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Catalog.byCategory(category)) { item in
                            ItemRow(
                                item: item,
                                unlocked: store.level >= item.level,
                                affordable: store.state.coins >= item.cost
                            ) {
                                store.startPlacing(item.id)
                                onClose()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

struct SeedsSheet: View {
    @ObservedObject var store: FarmStore
    let onClose: () -> Void

    var body: some View {
        SheetShell(title: "Seed Bag", onClose: onClose) {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Catalog.byCategory(.crop)) { item in
                        ItemRow(
                            item: item,
                            unlocked: store.level >= item.level,
                            affordable: store.state.coins >= item.cost
                        ) {
                            store.selectSeed(item.id)
                            onClose()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

struct BarnSheet: View {
    @ObservedObject var store: FarmStore
    let onClose: () -> Void

    private var stocked: [GoodDef] {
        Catalog.goods.filter { store.state.inventory[$0.id, default: 0] > 0 }
    }

    var body: some View {
        SheetShell(title: "Barn and Market", onClose: onClose) {
            VStack(spacing: 10) {
                if stocked.isEmpty {
                    Spacer()
                    Text("🏚️").font(.system(size: 64))
                    Text("Your barn is empty")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundStyle(Hue.ink)
                    Text("Harvest crops, trees and animals to fill it, then sell here or deliver orders.")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(Hue.ink.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(stocked, id: \.id) { good in
                                goodRow(good)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                    Button {
                        store.sellEverything()
                    } label: {
                        Text("Sell everything (+\(store.inventoryValue) coins)")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(Hue.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Hue.gold, in: Capsule())
                    }
                    .buttonStyle(FarmPressStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private func goodRow(_ good: GoodDef) -> some View {
        let count = store.state.inventory[good.id, default: 0]
        return HStack(spacing: 12) {
            Text(good.emoji)
                .font(.system(size: 32))
                .frame(width: 50, height: 50)
                .background(Hue.gold.opacity(0.3), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(good.name) x\(count)")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(Hue.ink)
                Text("\(good.price) coins each")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(Hue.ink.opacity(0.7))
            }
            Spacer(minLength: 4)
            Button {
                store.sell(good.id, count: 1)
            } label: {
                Text("Sell 1")
                    .font(.system(.footnote, design: .rounded, weight: .heavy))
                    .foregroundStyle(Hue.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Hue.ink.opacity(0.1), in: Capsule())
            }
            Button {
                store.sell(good.id, count: count)
            } label: {
                Text("Sell all")
                    .font(.system(.footnote, design: .rounded, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Hue.leaf, in: Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct OrdersSheet: View {
    @ObservedObject var store: FarmStore
    let onClose: () -> Void

    var body: some View {
        SheetShell(title: "Delivery Orders", onClose: onClose) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(store.state.orders) { order in
                        orderCard(order)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private func orderCard(_ order: Order) -> some View {
        let ids = order.needs.keys.sorted()
        let ready = store.canFulfil(order)
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(ids, id: \.self) { id in
                let need = order.needs[id] ?? 0
                let have = store.state.inventory[id, default: 0]
                let good = Catalog.good(id)
                HStack(spacing: 10) {
                    Text(good?.emoji ?? "").font(.system(size: 28))
                    Text(good?.name ?? id)
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Hue.ink)
                    Spacer()
                    Text("\(min(have, need))/\(need)")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(have >= need ? Hue.leaf : Hue.berry)
                    Image(systemName: have >= need ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(have >= need ? Hue.leaf : Hue.ink.opacity(0.3))
                }
            }
            Divider()
            HStack {
                Text("🪙 \(order.coins)   ⭐️ \(order.xp) XP")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(Hue.ink)
                Spacer()
                Button {
                    store.skipOrder(order)
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Hue.ink.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .background(Hue.ink.opacity(0.08), in: Circle())
                }
                Button {
                    store.fulfil(order)
                } label: {
                    Text("Deliver")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(ready ? Color.white : Hue.ink.opacity(0.4))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(ready ? Hue.leaf : Hue.ink.opacity(0.1), in: Capsule())
                }
                .disabled(!ready)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct MenuSheet: View {
    @ObservedObject var store: FarmStore
    let onClose: () -> Void
    @AppStorage("hapticsOn") private var hapticsOn = true
    @State private var confirmReset = false

    var body: some View {
        SheetShell(title: "Farm Menu", onClose: onClose) {
            ScrollView {
                VStack(spacing: 14) {
                    dailyCard
                    statsCard
                    Toggle(isOn: $hapticsOn) {
                        Text("Haptic feedback")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(Hue.ink)
                    }
                    .tint(Hue.leaf)
                    .padding(14)
                    .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button {
                        confirmReset = true
                    } label: {
                        Text("Start a new farm")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundStyle(Hue.berry)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Hue.berry.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .alert("Start a new farm?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset everything", role: .destructive) {
                store.resetFarm()
                onClose()
            }
        } message: {
            Text("This erases your coins, level, land and animals. It cannot be undone.")
        }
    }

    private var dailyCard: some View {
        let reward = store.dailyReward(streak: store.nextStreak)
        return VStack(spacing: 10) {
            HStack {
                Text("🎁").font(.system(size: 40))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily gift")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Hue.ink)
                    Text("Day streak: \(store.canClaimDaily ? store.nextStreak : store.state.streak)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(Hue.ink.opacity(0.7))
                }
                Spacer()
                Text("🪙 \(reward.coins)  💎 \(reward.gems)")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(Hue.ink)
            }
            Button {
                store.claimDaily()
            } label: {
                Text(store.canClaimDaily ? "Claim gift" : "Come back tomorrow")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundStyle(store.canClaimDaily ? Color.white : Hue.ink.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(store.canClaimDaily ? Hue.leaf : Hue.ink.opacity(0.08), in: Capsule())
            }
            .disabled(!store.canClaimDaily)
        }
        .padding(14)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var statsCard: some View {
        let land = store.state.tiles.filter { $0.unlocked }.count
        return HStack {
            statBlock(value: "\(store.level)", label: "Level")
            statBlock(value: "\(store.state.totalHarvests)", label: "Harvests")
            statBlock(value: "\(land)", label: "Land tiles")
        }
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(Hue.leaf)
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(Hue.ink.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Overlays

struct LevelUpOverlay: View {
    let info: LevelUpInfo
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            VStack(spacing: 12) {
                Text("🎉").font(.system(size: 64))
                Text("Level \(info.level)!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Hue.ink)
                Text("Rewards")
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(Hue.ink.opacity(0.6))
                HStack(spacing: 10) {
                    Text("+\(info.coins) 🪙")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Hue.gold.opacity(0.4), in: Capsule())
                    Text("+\(info.gems) 💎")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.18), in: Capsule())
                }
                .foregroundStyle(Hue.ink)

                if !info.unlocks.isEmpty {
                    Text("New unlocks")
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Hue.ink.opacity(0.6))
                        .padding(.top, 4)
                    HStack(spacing: 8) {
                        ForEach(info.unlocks.prefix(6)) { item in
                            Text(item.emoji)
                                .font(.system(size: 30))
                                .frame(width: 48, height: 48)
                                .background(Hue.grassA.opacity(0.35), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }

                Button {
                    Buzz.tap()
                    onClose()
                } label: {
                    Text("Awesome!")
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Hue.leaf, in: Capsule())
                }
                .buttonStyle(FarmPressStyle())
                .padding(.top, 6)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(Hue.cream, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 20, y: 8)
        }
    }
}

struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded, weight: .heavy))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.8), in: Capsule())
            .shadow(color: Color.black.opacity(0.3), radius: 6, y: 3)
    }
}

// MARK: - Main farm screen

struct FarmView: View {
    @ObservedObject var store: FarmStore
    @State private var sheet: FarmSheet? = nil
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Hue.sky, Color(red: 0.74, green: 0.92, blue: 0.70), Hue.grassB],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 8) {
                HUDView(store: store) { sheet = .menu }
                    .padding(.horizontal, 12)

                FarmBoard(store: store)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LinearGradient(colors: [Hue.wood, Hue.woodDark], startPoint: .top, endPoint: .bottom))
                    )
                    .overlay(alignment: store.selectedInBottomHalf ? .top : .bottom) {
                        if let index = store.selected {
                            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                                TileInfoCard(store: store, index: index, now: ctx.date) {
                                    sheet = .seeds
                                }
                            }
                            .padding(16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.85), value: store.selected)
                    .padding(.horizontal, 10)

                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    HintBar(store: store, now: ctx.date)
                }
                .padding(.horizontal, 10)

                DockView(store: store) { sheet = $0 }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 4)
            }

            VStack {
                if let toast = store.toast {
                    ToastView(text: toast)
                        .padding(.top, 64)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: store.toast)
            .allowsHitTesting(false)

            if let info = store.levelUp {
                LevelUpOverlay(info: info) { store.levelUp = nil }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.levelUp?.id)
        .sheet(item: $sheet) { which in
            Group {
                switch which {
                case .shop:
                    ShopSheet(store: store, onClose: { sheet = nil })
                case .seeds:
                    SeedsSheet(store: store, onClose: { sheet = nil })
                case .barn:
                    BarnSheet(store: store, onClose: { sheet = nil })
                case .orders:
                    OrdersSheet(store: store, onClose: { sheet = nil })
                case .menu:
                    MenuSheet(store: store, onClose: { sheet = nil })
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .alert(
            "Expand your farm?",
            isPresented: Binding(
                get: { store.pendingUnlock != nil },
                set: { if !$0 { store.pendingUnlock = nil } }
            ),
            presenting: store.pendingUnlock
        ) { index in
            Button("Cancel", role: .cancel) {}
            Button("Buy for \(store.unlockCost()) coins") {
                store.confirmUnlock(index)
            }
        } message: { _ in
            Text("Unlock this patch of land so you can grow even more.")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.save() }
        }
    }
}

// MARK: - Title screen

struct TitleView: View {
    var onPlay: () -> Void
    @State private var sway = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.30, green: 0.66, blue: 0.96), Hue.sky, Color(red: 0.80, green: 0.94, blue: 0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    Text("☀️")
                        .font(.system(size: 90))
                        .position(x: geo.size.width * 0.82, y: geo.size.height * 0.12)
                    Text("☁️")
                        .font(.system(size: 70))
                        .position(x: geo.size.width * 0.18, y: geo.size.height * 0.16)
                        .offset(x: sway ? 14 : -14)
                    Text("☁️")
                        .font(.system(size: 48))
                        .position(x: geo.size.width * 0.62, y: geo.size.height * 0.27)
                        .offset(x: sway ? -10 : 10)

                    Ellipse()
                        .fill(Hue.grassA)
                        .frame(width: geo.size.width * 1.6, height: geo.size.height * 0.42)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.98)
                    Ellipse()
                        .fill(Hue.grassB)
                        .frame(width: geo.size.width * 1.2, height: geo.size.height * 0.3)
                        .position(x: geo.size.width * 0.9, y: geo.size.height * 0.95)

                    Text("🏡")
                        .font(.system(size: 110))
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.64)
                    HStack(spacing: 6) {
                        ForEach(["🌽", "🥕", "🍅", "🌻", "🍓"], id: \.self) { e in
                            Text(e).font(.system(size: 34))
                        }
                    }
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.76)
                    HStack(spacing: 18) {
                        Text("🐄").font(.system(size: 44))
                        Text("🐑").font(.system(size: 40))
                        Text("🐔").font(.system(size: 36))
                    }
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.84)
                }
            }

            VStack(spacing: 8) {
                Spacer().frame(height: 70)
                Text("Sunny Acres")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .shadow(color: Hue.woodDark.opacity(0.7), radius: 0, x: 0, y: 4)
                Text("Plant. Harvest. Prosper.")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(Hue.woodDark)
                Spacer()
                Button {
                    Buzz.success()
                    onPlay()
                } label: {
                    Text("Start Farming")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(Hue.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [Hue.gold, Color(red: 1.0, green: 0.62, blue: 0.15)], startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                        .shadow(color: Hue.woodDark.opacity(0.5), radius: 0, x: 0, y: 5)
                }
                .buttonStyle(FarmPressStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                sway = true
            }
        }
    }
}

// MARK: - Root

struct ContentView: View {
    @StateObject private var store = FarmStore()
    @State private var started = false

    var body: some View {
        ZStack {
            if started {
                FarmView(store: store)
                    .transition(.opacity)
            } else {
                TitleView {
                    withAnimation(.easeInOut(duration: 0.4)) { started = true }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
