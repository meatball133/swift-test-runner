//
//  File.swift
//
//
//  Created by William Neumann on 5/2/20.
//

// TODO: - Clean up this messy-ass file

// MARK: - Base definitions
public struct ErrStr: Error, CustomStringConvertible, ExpressibleByStringLiteral {
  public typealias StringLiteralType = String

  public var description: String
  public init(stringLiteral value: String) {
    self.description = value
  }
  public init(_ desc: String) { self.description = desc }
}
public struct Parser<A> {
  public let run: (inout Substring) -> Result<A, ErrStr>
}
extension Parser {
  public func run(_ str: String) -> (match: Result<A, ErrStr>, rest: Substring) {
    var str = str[...]
    let match = self.run(&str)
    return (match, str)
  }
}
// MARK: - Basic type parsers, int, double, char, etc.
extension Parser where A == Int {
  public static var int: Parser<A> {
    Parser<A> { str in
      guard !str.isEmpty else { return .failure("Input string was empty") }
      var rest = str
      var sign = 1
      switch rest.first! {
      case "-":
        sign = -1
        rest.removeFirst()
      case "+": rest.removeFirst()
      default: break
      }
      let prefix = rest.prefix(while: { $0.isWholeNumber })
      guard let match = Int(prefix) else { return .failure("Prefix was not a number") }
      str = rest
      str.removeFirst(prefix.count)
      return .success(match * sign)
    }
  }
}
extension Parser where A == Character {
  public static var char: Parser<A> {
    Parser<A> { str in
      guard let ch = str.popFirst() else { return .failure("Input string was empty") }
      return .success(ch)
    }
  }
}
extension Parser where A == Double {
  public static var double: Parser<A> {
    Parser<A> { str in
      guard !str.isEmpty else { return .failure("The input was empty") }
      var rest = str
      var sign = 1.0
      switch rest.first! {
      case "-":
        sign = -1.0
        rest.removeFirst()
      case "+": rest.removeFirst()
      default: break
      }
      let whole = rest.prefix(while: { $0.isWholeNumber })
      let dot = rest[whole.endIndex...].prefix(while: { $0 == "." })
      let fraction = rest[dot.endIndex...].prefix(while: { $0.isWholeNumber })
      guard !whole.isEmpty || (!dot.isEmpty && !fraction.isEmpty) else {
        return .failure("Input was a '.' without any numbers surrounding it")
      }
      var dub = Double(whole) ?? 0.0
      switch (dot.count, fraction.count) {
      case (0, _): str = rest[whole.endIndex...]
      case (1, 0): str = rest[dot.endIndex...]
      case let (n, _) where n > 1: str = rest[whole.endIndex...].dropFirst()
      case (1, _):
        guard let frac = Double(".\(fraction)") else {
          return .failure(
            "double: Weird case 1 - Got a trailing '.###' but couldn't convert it to a double")
        }
        str = rest[fraction.endIndex...]
        dub += frac
      default:
        return .failure(
          "double: Weird case 2 - default case that was required to prove switch exhaustivity, should literally never be hit"
        )
      }
      return .success(sign * dub)
    }
  }
}
extension Parser {
  public static func always(_ a: A) -> Parser {
    Parser { _ in .success(a) }
  }
  public static var never: Parser {
    Parser { _ in .failure("never parser always fails") }
  }
}
// MARK: - Functional manipulations, map, flatmap, zips of many arities, etc.
extension Parser {
  public func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
    Parser<B> { str in
      self.run(&str).map(f)
    }
  }
  public func flatMap<B>(_ f: @escaping (A) -> Parser<B>) -> Parser<B> {
    Parser<B> { str in
      var strX = str[...]
      switch self.run(&strX) {
      case .failure(let err): return .failure(err)
      case let .success(a):
        switch f(a).run(&strX) {
        case .failure(let err): return .failure(err)
        case let sb:
          str = strX
          return sb
        }
      }
    }
  }
  public func ignore() -> Parser<Void> {
    Parser<Void> { str in
      let _ = self.run(&str)
      return .success(())
    }
  }

  public func eatNewline() -> Parser {
    return Parser.keep(
      self, discard: Parser<Void>.choose(Parser<Void>.literal("\n"), Parser<Void>.end))
  }

  public func eatLine() -> Parser {
    let eol = Parser<Void>.choose(Parser<Void>.literal("\n"), Parser<Void>.end)
    return Parser.keep(self, discard: eol)
  }

}
//public func flatMAp<A, B>(_ f: @escaping (A) -> Parser<B>) -> (Parser<A>) -> Parser<B> {
//    return { pa in
//        Parser<B> { str in
//            var strX = str[...]
//            switch pa.run(&strX) {
//            case .failure(let err): return .failure(err)
//            case let .success(a):
//                switch f(a).run(&strX) {
//                case .failure(let err): return.failure(err)
//                case let sb:
//                    str = strX
//                    return sb
//                }
//            }
//        }
//    }
//}
public func zip<A, B>(_ pa: Parser<A>, _ pb: Parser<B>) -> Parser<(A, B)> {
  Parser<(A, B)> { str in
    var strX = str[...]
    let a = pa.run(&strX)
    let b = pb.run(&strX)
    switch (a, b) {
    case (.failure(let errA), .failure(let errB)):
      return .failure(ErrStr("\(errA) and \(errB)"))
    case (.failure(let errA), _): return .failure(errA)
    case (_, .failure(let errB)): return .failure(errB)
    case (.success(let sa), .success(let sb)):
      str = strX
      return .success((sa, sb))
    }
  }
}
public func zip<A, B, C>(with f: @escaping (A, B) -> C, _ pa: Parser<A>, _ pb: Parser<B>) -> Parser<
  C
> {
  zip(pa, pb).map(f)
}
public func zip<A, B, C>(_ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>) -> Parser<(A, B, C)> {
  zip(pa, zip(pb, pc)).map { ($0, $1.0, $1.1) }
}
public func zip<A, B, C, D>(
  with f: @escaping (A, B, C) -> D, _ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>
) -> Parser<D> {
  zip(pa, pb, pc).map(f)
}
public func zip<A, B, C, D>(_ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>, _ pd: Parser<D>)
  -> Parser<(A, B, C, D)>
{
  zip(pa, zip(pb, pc, pd)).map { ($0, $1.0, $1.1, $1.2) }
}
public func zip<A, B, C, D, E>(
  with f: @escaping (A, B, C, D) -> E, _ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>,
  _ pd: Parser<D>
) -> Parser<E> {
  zip(pa, pb, pc, pd).map(f)
}
public func zip<A, B, C, D, E>(
  _ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>,
  _ pd: Parser<D>, _ pe: Parser<E>
) -> Parser<(A, B, C, D, E)> {
  zip(pa, zip(pb, pc, pd, pe)).map { ($0, $1.0, $1.1, $1.2, $1.3) }
}
public func zip<A, B, C, D, E, F>(
  with f: @escaping (A, B, C, D, E) -> F,
  _ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>, _ pd: Parser<D>, _ pe: Parser<E>
) -> Parser<F> {
  zip(pa, pb, pc, pd, pe).map(f)
}
public func zip<A, B, C, D, E, F>(
  _ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>,
  _ pd: Parser<D>, _ pe: Parser<E>, _ pf: Parser<F>
) -> Parser<(A, B, C, D, E, F)> {
  zip(pa, zip(pb, pc, pd, pe, pf)).map { ($0, $1.0, $1.1, $1.2, $1.3, $1.4) }
}
public func zip<A, B, C, D, E, F, G>(
  with f: @escaping (A, B, C, D, E, F) -> G,
  _ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>,
  _ pd: Parser<D>, _ pe: Parser<E>, _ pf: Parser<F>
) -> Parser<G> {
  zip(pa, pb, pc, pd, pe, pf).map(f)
}
public func zip<A, B, C, D, E, F, G>(
  _ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>, _ pd: Parser<D>,
  _ pe: Parser<E>, _ pf: Parser<F>, _ pg: Parser<G>
) -> Parser<(A, B, C, D, E, F, G)> {
  zip(pa, zip(pb, pc, pd, pe, pf, pg)).map { ($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5) }
}
public func zip<A, B, C, D, E, F, G, H>(
  with f: @escaping (A, B, C, D, E, F, G) -> H,
  _ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>, _ pd: Parser<D>,
  _ pe: Parser<E>, _ pf: Parser<F>, _ pg: Parser<G>
) -> Parser<H> {
  zip(pa, pb, pc, pd, pe, pf, pg).map(f)
}
public func zip<A, B, C, D, E, F, G, H>(
  _ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>, _ pd: Parser<D>,
  _ pe: Parser<E>, _ pf: Parser<F>, _ pg: Parser<G>, _ ph: Parser<H>
) -> Parser<(A, B, C, D, E, F, G, H)> {
  zip(pa, zip(pb, pc, pd, pe, pf, pg, ph)).map { ($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6) }
}
public func zip<A, B, C, D, E, F, G, H, I>(
  with f: @escaping (A, B, C, D, E, F, G, H) -> I,
  _ pa: Parser<A>, _ pb: Parser<B>, _ pc: Parser<C>, _ pd: Parser<D>,
  _ pe: Parser<E>, _ pf: Parser<F>, _ pg: Parser<G>, _ ph: Parser<H>
) -> Parser<I> {
  zip(pa, pb, pc, pd, pe, pf, pg, ph).map(f)
}
public func nonConsuming<A>(_ parser: Parser<A>) -> Parser<A> {
  Parser<A> { str in
    var strX = str
    return parser.run(&strX)
  }
}

public func not<A>(_ parser: Parser<A>) -> Parser<Void> {
  Parser<Void> { str in
    switch nonConsuming(parser).run(&str) {
    case .success:
      return .failure("Wrapped parser returned .success")
    case .failure:
      return .success(())
    }
  }
}

// MARK: - Basic combinators
public enum Either<A, B> {
  case left(A)
  case right(B)
}
public func chomp(while pred: @escaping (Character) -> Bool) -> Parser<Substring> {
  Parser<Substring> { str in
    let prefix = str.prefix(while: pred)
    if prefix.isEmpty { return .failure("No matches at front of input") }
    str.removeFirst(prefix.count)
    return .success(prefix)
  }
}

public func chomp(until pred: @escaping (Character) -> Bool) -> Parser<Substring> {
  Parser<Substring> { str in
    let prefix = str.prefix(while: { !pred($0) })
    if prefix.isEmpty { return .failure("No matches at front of input") }
    str.removeFirst(prefix.count)
    return .success(prefix)
  }
}

public func prefix(while pred: @escaping (Character) -> Bool) -> Parser<Substring> {
  Parser<Substring> { str in
    let prefix = str.prefix(while: pred)
    str.removeFirst(prefix.count)
    return .success(prefix)
  }
}

public func prefix(until pred: @escaping (Character) -> Bool) -> Parser<Substring> {
  Parser<Substring> { str in
    let prefix = str.prefix(while: { !pred($0) })
    str.removeFirst(prefix.count)
    return .success(prefix)
  }
}

public func drop(while pred: @escaping (Character) -> Bool) -> Parser<Void> {
  Parser<Void> { str in
    let prefix = str.prefix(while: pred)
    str.removeFirst(prefix.count)
    return .success(())
  }
}
public func set<A, T: Collection>(_ parser: Parser<A>, containedIn set: T) -> Parser<A>
where A: Hashable, T.Element == A {
  Parser<A> { str in
    let pristine = str
    switch parser.run(&str) {
    case .failure(let err): return .failure(err)
    case .success(let a):
      if set.contains(a) {
        return .success(a)
      } else {
        str = pristine
        return .failure(ErrStr("set: Parsed value \(a) is not is the specified set"))
      }
    }
  }
}
extension Parser {
  public static func either<B>(_ pa: Parser, _ pb: Parser<B>) -> Parser<Either<A, B>> {
    Parser<Either<A, B>> { str in
      var strX = str[...]
      var err: ErrStr
      switch pa.run(&strX) {
      case let .success(a):
        str = strX
        return .success(.left(a))
      case .failure(let errA): err = errA
      }
      switch pb.run(&strX) {
      case .success(let b):
        str = strX
        return .success(.right(b))
      case .failure(let errB): return .failure(ErrStr("\(err) and \(errB)"))
      }
    }
  }

  public static func star(_ parser: Parser, separatedBy s: Parser<Void> = .always(())) -> Parser<
    [A]
  > {
    Parser<[A]> { str in
      var rest = str
      var res = [A]()
      var p = parser.run(&str)
      while case let .success(a) = p {
        rest = str
        res.append(a)
        if case .failure(_) = s.run(&str) { return .success(res) }
        p = parser.run(&str)
      }
      str = rest
      return .success(res)
    }
  }
  public static func star(_ parser: Parser, until u: Parser<Void>) -> Parser<[A]> {
    Parser<[A]> { str in
      var rest = str
      var res = [A]()
      var p = parser.run(&str)
      while case let .success(a) = p {
        rest = str
        res.append(a)
        if case .success(_) = u.run(&str) { return .success(res) }
        p = parser.run(&str)
      }
      str = rest
      return .success(res)
    }
  }
  public static func plus(_ parser: Parser, separatedBy s: Parser<Void> = .always(())) -> Parser<
    [A]
  > {
    Parser<[A]> { str in
      var rest = str
      var res = [A]()
      var p = parser.run(&str)
      while case let .success(a) = p {
        rest = str
        res.append(a)
        if case .failure(_) = s.run(&str) { return .success(res) }
        p = parser.run(&str)
      }
      if res.isEmpty { return .failure("No matches") }
      str = rest
      return .success(res)
    }
  }
  public static func plus(_ parser: Parser, until u: Parser<Void>) -> Parser<[A]> {
    Parser<[A]> { str in
      var rest = str
      var res = [A]()
      var p = parser.run(&str)
      while case let .success(a) = p {
        rest = str
        res.append(a)
        if case .success(_) = u.run(&str) { return .success(res) }
        p = parser.run(&str)
      }
      if res.isEmpty { return .failure("No matches") }
      str = rest
      return .success(res)
    }
  }
  public static func keep<B>(_ pa: Parser, discard pb: Parser<B>) -> Parser {
    Parser { str in
      var strX = str[...]
      switch pa.run(&strX) {
      case .success(let a):
        switch pb.run(&strX) {
        case .failure(let errB): return .failure(errB)
        default:
          str = strX
          return .success(a)
        }
      case let fail: return fail
      }
    }
  }
  public static func discard<B>(_ pb: Parser<B>, keep pa: Parser) -> Parser {
    Parser { str in
      var strX = str[...]
      switch pb.run(&strX) {
      case .success:
        switch pa.run(&strX) {
        case .failure(let errA): return .failure(errA)
        case .success(let a):
          str = strX
          return .success(a)
        }
      case .failure(let errB): return .failure(errB)
      }
    }
  }
  public static func choose(_ p1: Parser, _ p2: Parser) -> Parser {
    Parser { str in
      var strX = str[...]
      switch p1.run(&strX) {
      case .failure(let errA):
        switch p2.run(&strX) {
        case .failure(let errB): return .failure(ErrStr("\(errA) and \(errB)"))
        case let succ:
          str = strX
          return succ
        }
      case let succ:
        str = strX
        return succ
      }
    }
  }
  public static func choice(_ parsers: [Parser]) -> Parser {
    Parser { str in
      var strX = str[...]
      var errs = [ErrStr]()
      for parser in parsers {
        switch parser.run(&strX) {
        case .failure(let err): errs.append(err)
        case let succ:
          str = strX
          return succ
        }
      }
      return .failure(ErrStr(errs.map { $0.description }.joined(separator: " and ")))
    }
  }

  public static func trim(_ parser: Parser) -> Parser {
    let trimWS = drop(while: { $0.isWhitespace })
    let trimFront = discard(trimWS, keep: parser)
    return keep(trimFront, discard: trimWS)
  }

}
extension Parser where A == String {
  public static func string(_ lit: String, caseInsensitive ci: Bool = false) -> Parser<A> {
    Parser<A> { str in
      let res = str.prefix(lit.count)
      let pred = ci ? res.lowercased() == lit.lowercased() : str.hasPrefix(lit)
      guard pred else { return .failure(ErrStr("\(lit) was not at the front of the input")) }
      str.removeFirst(lit.count)
      return .success(String(res))
    }
  }
}

extension Parser where A == Substring {
  public static var rest: Parser<A> {
    Parser<A> { str in
      let res = str[...]
      str.removeAll()
      return .success(res)
    }
  }
}

extension Parser where A == Void {
  public static var whitespace: Parser {
    chomp(while: { $0.isWhitespace }).map { _ in () }
  }

  public static var end: Parser {
    Parser { str in
      return str.isEmpty ? .success(()) : .failure("More input left to parse")
    }
  }

  public static func literal(_ lit: String, caseInsensitive ci: Bool = false) -> Parser<A> {
    Parser<A> { str in
      let pred = ci ? str.prefix(lit.count).lowercased() == lit.lowercased() : str.hasPrefix(lit)
      guard pred else { return .failure(ErrStr("\(lit) was not at the front of the input")) }
      str.removeFirst(lit.count)
      return .success(())
    }
  }
}
public func nOf<A>(_ parser: Parser<A>, n: Int) -> Parser<[A]> {
  Parser<[A]> { str in
    var res = [A]()
    for _ in 1...n {
      if case let .success(a) = parser.run(&str) {
        res.append(a)
      } else {
        return .failure(ErrStr("nOf: There were fewer than \(n) items to parse"))
      }
    }
    return .success(res)
  }
}
public func nOf<A>(_ parser: Parser<A>, n: Int, separatedBy s: Parser<Void> = .always(()))
  -> Parser<[A]>
{
  Parser<[A]> { str in
    var res = [A]()
    for _ in 1...n {
      if case let .success(a) = parser.run(&str) {
        res.append(a)
      } else {
        break
      }
      if case .failure(_) = s.run(&str) { break }
    }
    if res.count != n { return .failure(ErrStr("nOf: There were fewer than \(n) items to parse")) }
    return .success(res)
  }
}
