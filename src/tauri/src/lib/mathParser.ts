import { invoke } from '@tauri-apps/api/core';

/**
 * Evaluates a mathematical expression (e.g. "100 * 2.5 + (50 / 2)")
 * Uses Tauri Rust backend if available, with a fallback TS evaluator.
 */
export async function evaluateMathExpression(input: string): Promise<number> {
  const cleanInput = input.trim();
  if (!cleanInput) {
    throw new Error('Empty input');
  }

  // Try calling Rust backend via Tauri
  try {
    const result = await invoke<number>('evaluate_math', { expr: cleanInput });
    if (typeof result === 'number' && !isNaN(result)) {
      return result;
    }
  } catch (e) {
    // If not running inside Tauri webview or Rust call fails, fallback to TS evaluator
  }

  return parseAndEvaluateTS(cleanInput);
}

/**
 * Pure TypeScript Shunting-Yard math evaluator fallback
 */
export function parseAndEvaluateTS(expr: string): number {
  const sanitized = expr.replace(/\s+/g, '');
  if (!sanitized) throw new Error('Empty expression');

  // Tokenizer
  const tokens: string[] = [];
  let i = 0;

  while (i < sanitized.length) {
    const ch = sanitized[i];
    if ('0123456789.'.includes(ch)) {
      let numStr = '';
      while (i < sanitized.length && '0123456789.'.includes(sanitized[i])) {
        numStr += sanitized[i];
        i++;
      }
      tokens.push(numStr);
    } else if ('+-*/()'.includes(ch)) {
      // Unary minus check
      if (ch === '-' && (tokens.length === 0 || tokens[tokens.length - 1] === '(' || '+-*/'.includes(tokens[tokens.length - 1]))) {
        i++;
        let numStr = '-';
        while (i < sanitized.length && '0123456789.'.includes(sanitized[i])) {
          numStr += sanitized[i];
          i++;
        }
        if (numStr === '-') throw new Error('Invalid negative number format');
        tokens.push(numStr);
      } else {
        tokens.push(ch);
        i++;
      }
    } else {
      throw new Error(`Invalid token: ${ch}`);
    }
  }

  // Shunting-Yard algorithm to RPN
  const outputQueue: string[] = [];
  const operatorStack: string[] = [];

  const precedence: Record<string, number> = {
    '+': 1,
    '-': 1,
    '*': 2,
    '/': 2
  };

  for (const token of tokens) {
    if (!isNaN(Number(token))) {
      outputQueue.push(token);
    } else if ('+-*/'.includes(token)) {
      while (
        operatorStack.length > 0 &&
        operatorStack[operatorStack.length - 1] !== '(' &&
        precedence[operatorStack[operatorStack.length - 1]] >= precedence[token]
      ) {
        outputQueue.push(operatorStack.pop()!);
      }
      operatorStack.push(token);
    } else if (token === '(') {
      operatorStack.push(token);
    } else if (token === ')') {
      while (operatorStack.length > 0 && operatorStack[operatorStack.length - 1] !== '(') {
        outputQueue.push(operatorStack.pop()!);
      }
      if (operatorStack.length === 0) throw new Error('Mismatched parentheses');
      operatorStack.pop(); // Pop '('
    }
  }

  while (operatorStack.length > 0) {
    const op = operatorStack.pop()!;
    if (op === '(' || op === ')') throw new Error('Mismatched parentheses');
    outputQueue.push(op);
  }

  // Evaluate RPN
  const evalStack: number[] = [];
  for (const token of outputQueue) {
    if (!isNaN(Number(token))) {
      evalStack.push(Number(token));
    } else {
      if (evalStack.length < 2) throw new Error('Invalid math expression');
      const b = evalStack.pop()!;
      const a = evalStack.pop()!;
      switch (token) {
        case '+': evalStack.push(a + b); break;
        case '-': evalStack.push(a - b); break;
        case '*': evalStack.push(a * b); break;
        case '/':
          if (b === 0) throw new Error('Division by zero');
          evalStack.push(a / b);
          break;
      }
    }
  }

  if (evalStack.length !== 1) throw new Error('Invalid math evaluation');
  return evalStack[0];
}
