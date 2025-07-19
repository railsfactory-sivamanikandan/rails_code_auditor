# 🚀 RailsCodeAuditor

**Rails Code Auditor** is a Ruby gem that automatically audits your Ruby on Rails applications for security, performance, code quality, and licensing issues.

It integrates popular auditing tools and wraps the results in visually rich HTML and PDF reports. It also leverages **LLMs (Ollama with LLaMA 3)** to provide intelligent improvement suggestions.

---

## ✨ Features (Automated)

### ✅ Automatically runs code quality tools:
  - **Security Audit** using [Brakeman](https://github.com/presidentbeef/brakeman)
  - **Dependency Vulnerability Scan** via [Bundler Audit](https://github.com/rubysec/bundler-audit)
  - **Code Style Check** using [RuboCop](https://github.com/rubocop/rubocop)
  - **Rails Best Practices Analysis** via [rails_best_practices](https://github.com/flyerhzm/rails_best_practices)
  - **Code Duplication Detection** using [Flay](https://github.com/seattlerb/flay)
  - **Code Complexity Score** using [Flog](https://github.com/seattlerb/flog)
  - **License Compliance** via [License Finder](https://github.com/pivotal/LicenseFinder)
  - **Code Smell Detection** with [Reek](https://github.com/troessner/reek)
  - **Code Quality Visualization** using [RubyCritic](https://github.com/whitesmith/rubycritic)
  - **Test Coverage Analysis** using [SimpleCov](https://github.com/simplecov-ruby/simplecov)

### 📄 Report Generation
- Automatically generates **HTML** and **PDF** reports for each tool
- Graphical charts using Gruff.
- Beautiful PDF report generation using Prawn and Prawn::Table.
- PDF reports use **Puppeteer** via the `grover` gem (if available).
- Automated Report Merging into a single PDF file
- Organizes all output under the `report/` directory

### 🧠 AI-Powered Code Review
- Integrates with **Ollama** using the **LLaMA 3** model
- Summarizes audit findings using LLMs
- Provides human-like suggestions for improving code structure and test coverage
- Analyzes both **source code** and **generated reports**

### 💡 Fully Automatic
- One command to run all audits, generate reports, and get AI recommendations — no manual steps required

---

## 📦 Installation

Add this to your application's `Gemfile`:

```ruby
gem 'rails_code_auditor'
```

Then run:

```bash
bundle install
```

## 🚀 Usage
Run the full audit and generate reports:

```bash
bundle exec rails_code_auditor
```
Enable AI code review with Ollama:

```bash
bundle exec rails_code_auditor --use-llm
```
## 🧠 LLM Integration with Ollama
Install Ollama (https://ollama.com/)

Start the LLaMA 3 model locally:

```bash
ollama run llama3
```
Run the gem with --use-llm to get AI-generated insights.

## 🧪 SimpleCov Setup
Ensure simplecov is added to your Gemfile:

```ruby
gem 'simplecov', require: false
```

## 🧰 Puppeteer Setup (Optional)
Install Puppeteer using Yarn or npm:

```bash
yarn add puppeteer
```
PDF report generation will be skipped if Puppeteer isn't installed — a warning will be shown, but HTML reports will still be generated.

## 📁 Output Structure
```pgsql
report/
├── pdf/
│   ├── rubycritic.pdf
│   ├── rails_best_practices.pdf
│   └── rubocop.pdf (if available)
├── rubycritic/
│   └── index.html
├── rails_best_practices.html
├── rubocop.html
└── coverage/
    └── index.html
```

## 🔧 Configuration
You can customize what tools to enable, file paths, and output formats using an initializer or environment flags (coming soon)

# 🙌 Contributing
Pull requests are welcome! Please fork the repo and open a PR. For major changes, open an issue first to discuss your proposal.

## 📄 License
MIT License
© 2025 sivamanikandan

## 📌 Coming Soon
- Report dashboard view in browser
- GitHub Actions integration
- Custom LLM model support

```yaml
---

Let me know if you want:
- Badge support (`Gem`, `License`, `CI`, etc.)
- Project logo or screenshot inclusion
- Interactive web-based report viewing via browser
- A `bin/rails_code_auditor` launcher script

I can generate all of these if needed.
```