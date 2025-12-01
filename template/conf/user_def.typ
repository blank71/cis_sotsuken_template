#let emph_color(color, body) = {
  show emph: it => {
    set text(color)
    it.body
  }
  emph(body)
}
#let underline_color(color, body) = { underline(stroke: 1pt + color, [#body]) }
#let emph_red(body) = {
  emph_color(red, body)
}
#let underline_red(body) = { underline_color(red, body) }
#let underline_blue(body) = { underline_color(blue, body) }

#let theorem-counter = counter("theorem")
#let lemma-counter = counter("lemma")
#let definition-counter = counter("definition")
#let proof-counter = counter("proof")

#let theorem(body) = {
  set par(first-line-indent: (amount: 0em))
  theorem-counter.step()
  v(0.35em)
  context [*定理 #theorem-counter.display().* #h(0.65em)]
  body
}

#let lemma(body) = {
  set par(first-line-indent: (amount: 0em))
  lemma-counter.step()
  v(0.35em)
  context [*補題 #lemma-counter.display().* #h(0.65em)]
  body
}

#let definition(body) = {
  set par(first-line-indent: (amount: 0em))
  definition-counter.step()
  v(0.35em)
  context [*定義 #definition-counter.display().* #h(0.65em)]
  body
}

#let proof(body) = {
  set par(first-line-indent: (amount: 0em))
  v(0.35em)
  [*証明.* #h(0.65em)]
  body
}

#import "@preview/algorithmic:1.0.7": *

// AST を再帰的に探索して最後の行にL字型マーカーを追加し、インデントを下げる共通関数
#let process-ast(ast, is-last-in-parent: false, depth: 0) = {
  if type(ast) == content {
    // content は単一行
    if is-last-in-parent {
      let l-marker = box(
        stroke: (left: 0.5pt + luma(200), bottom: 0.5pt + luma(200)),
        inset: (left: 0pt, bottom: 0.5em, right: 1.0em, top: 0pt),
        outset: (left: -0.3em, bottom: -0.1em, right: -0.2em, top: 0.7em),
      )[]
      // インデントを下げて縦線を消し、L字マーカーを追加
      (change-indent: -2, body: (l-marker + ast,))
    } else {
      ast
    }
  } else if type(ast) == dictionary {
    // dictionary は change-indent と body を持つ構造
    let new-body = process-ast(ast.body, is-last-in-parent: is-last-in-parent, depth: depth + 1)
    (change-indent: ast.at("change-indent", default: 0), body: new-body)
  } else if type(ast) == array {
    // array は複数の要素
    if ast.len() == 0 {
      ast
    } else {
      let result = ()
      for i in range(ast.len()) {
        let item = ast.at(i)
        let is-last = is-last-in-parent and i == ast.len() - 1
        result.push(process-ast(item, is-last-in-parent: is-last, depth: depth))
      }
      result
    }
  } else {
    ast
  }
}

// L字終端を使う iflike（end を出力しない）
#let iflike-l-terminated(kw1: "", kw2: "", cond, ..body) = {
  let modified-body = process-ast(body.pos(), is-last-in-parent: true)
  (
    (strong(kw1) + " " + cond + " " + strong(kw2)),
    (change-indent: 2, body: modified-body),
  )
}

// Function
#let Function = {
  let call(
    name,
    kw: "function",
    inline: false,
    style: smallcaps,
    args,
    ..body,
  ) = (
    if inline {
      [#style(name)\(#arraify(args).join(", ")\):]
    } else {
      // end を出力せず、最後の行にL字型マーカーを追加
      let modified-body = process-ast(body.pos(), is-last-in-parent: true)
      (
        (strong(kw) + " " + style(name) + $(#arraify(args).join(", "))$ + ":"),
        (change-indent: 2, body: modified-body),
      )
    }
  )
  call.with(kw: "function", inline: false)
}

// For, If, While, Else, ElseIf を L字終端で再定義
#let For = iflike-l-terminated.with(kw1: "for", kw2: "do")
#let If = iflike-l-terminated.with(kw1: "if", kw2: "then")
#let While = iflike-l-terminated.with(kw1: "while", kw2: "do")
#let Else = iflike-l-terminated.with(kw1: "else", kw2: "", "")
#let ElseIf = iflike-l-terminated.with(kw1: "else if", kw2: "then")

// IfElseChain を L字終端で再定義
#let IfElseChain(..conditions-and-bodies) = {
  let result = ()
  let conditions-and-bodies = conditions-and-bodies.pos()
  let len = conditions-and-bodies.len()
  let i = 0

  while i < len {
    if i == len - 1 and calc.odd(len) {
      // Last element is the "else" block - L字終端を適用
      result.push(Else(..arraify(conditions-and-bodies.at(i))))
    } else if calc.even(i) {
      // Condition
      let cond = conditions-and-bodies.at(i)
      let body = arraify(conditions-and-bodies.at(i + 1))
      if i == 0 {
        // First condition is a regular "if" (no L字終端、後続があるため)
        result.push(iflike-unterminated(kw1: "if", kw2: "then", cond, ..body))
      } else if i + 2 >= len {
        // Last condition - L字終端を適用
        result.push(ElseIf(cond, ..body))
      } else {
        // Intermediate conditions (no L字終端、後続があるため)
        result.push(iflike-unterminated(kw1: "else if", kw2: "then", cond, ..body))
      }
    }
    i = i + 1
  }
  result
}
#let Assign(var, val) = (var + " " + $=$ + " " + arraify(val).join(", "),)
#let fbox(body) = {
  box(
    stroke: 0.5pt,
    inset: 0.2em,
    baseline: 0.2em,
    [#body],
  )
}


#let rmP = [$"P"$]
#let rmNP = [$"NP"$]

