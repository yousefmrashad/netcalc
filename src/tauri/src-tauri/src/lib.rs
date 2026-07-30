use std::str::FromStr;

#[tauri::command]
fn evaluate_math(expr: String) -> Result<f64, String> {
    let expr_clean = expr.replace(' ', "");
    if expr_clean.is_empty() {
        return Err("Empty expression".into());
    }
    
    // Quick evaluation for standard arithmetic expression in Rust
    match eval_simple(&expr_clean) {
        Ok(val) => Ok(val),
        Err(e) => Err(e),
    }
}

fn eval_simple(s: &str) -> Result<f64, String> {
    // Simple recursive descent expression parser for + - * / and parentheses
    let tokens = tokenize(s)?;
    let mut pos = 0;
    parse_expr(&tokens, &mut pos)
}

#[derive(Debug, Clone, PartialEq)]
enum Token {
    Num(f64),
    Op(char),
    LParen,
    RParen,
}

fn tokenize(s: &str) -> Result<Vec<Token>, String> {
    let mut tokens = Vec::new();
    let chars: Vec<char> = s.chars().collect();
    let mut i = 0;

    while i < chars.len() {
        let c = chars[i];
        if c.is_ascii_digit() || c == '.' {
            let start = i;
            while i < chars.len() && (chars[i].is_ascii_digit() || chars[i] == '.') {
                i += 1;
            }
            let num_str: String = chars[start..i].iter().collect();
            let num = f64::from_str(&num_str).map_err(|_| format!("Invalid number: {}", num_str))?;
            tokens.push(Token::Num(num));
        } else if c == '+' || c == '-' || c == '*' || c == '/' {
            // Handle unary minus
            if c == '-' && (tokens.is_empty() || matches!(tokens.last(), Some(Token::Op(_)) | Some(Token::LParen))) {
                // Peek ahead for number
                i += 1;
                if i < chars.len() && (chars[i].is_ascii_digit() || chars[i] == '.') {
                    let start = i;
                    while i < chars.len() && (chars[i].is_ascii_digit() || chars[i] == '.') {
                        i += 1;
                    }
                    let num_str: String = chars[start..i].iter().collect();
                    let num = f64::from_str(&num_str).map_err(|_| format!("Invalid number: {}", num_str))?;
                    tokens.push(Token::Num(-num));
                } else {
                    return Err("Invalid unary minus usage".into());
                }
            } else {
                tokens.push(Token::Op(c));
                i += 1;
            }
        } else if c == '(' {
            tokens.push(Token::LParen);
            i += 1;
        } else if c == ')' {
            tokens.push(Token::RParen);
            i += 1;
        } else {
            return Err(format!("Unexpected character: {}", c));
        }
    }
    Ok(tokens)
}

fn parse_expr(tokens: &[Token], pos: &mut usize) -> Result<f64, String> {
    let mut val = parse_term(tokens, pos)?;

    while *pos < tokens.len() {
        if let Token::Op(op) = tokens[*pos] {
            if op == '+' || op == '-' {
                *pos += 1;
                let right = parse_term(tokens, pos)?;
                if op == '+' {
                    val += right;
                } else {
                    val -= right;
                }
                continue;
            }
        }
        break;
    }
    Ok(val)
}

fn parse_term(tokens: &[Token], pos: &mut usize) -> Result<f64, String> {
    let mut val = parse_factor(tokens, pos)?;

    while *pos < tokens.len() {
        if let Token::Op(op) = tokens[*pos] {
            if op == '*' || op == '/' {
                *pos += 1;
                let right = parse_factor(tokens, pos)?;
                if op == '*' {
                    val *= right;
                } else {
                    if right == 0.0 {
                        return Err("Division by zero".into());
                    }
                    val /= right;
                }
                continue;
            }
        }
        break;
    }
    Ok(val)
}

fn parse_factor(tokens: &[Token], pos: &mut usize) -> Result<f64, String> {
    if *pos >= tokens.len() {
        return Err("Unexpected end of expression".into());
    }

    match &tokens[*pos] {
        Token::Num(n) => {
            let val = *n;
            *pos += 1;
            Ok(val)
        }
        Token::LParen => {
            *pos += 1;
            let val = parse_expr(tokens, pos)?;
            if *pos >= tokens.len() || tokens[*pos] != Token::RParen {
                return Err("Missing closing parenthesis".into());
            }
            *pos += 1;
            Ok(val)
        }
        _ => Err("Expected number or '('".into()),
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![evaluate_math])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
