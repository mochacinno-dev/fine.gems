require 'sinatra'
require 'sinatra/base'
require 'erb'
require 'json'
require 'date'

# Data storage file
DATA_FILE = 'finance_data.json'

# Initialize data structure
def load_data
  if File.exist?(DATA_FILE)
    JSON.parse(File.read(DATA_FILE))
  else
    { 'transactions' => [], 'budgets' => {} }
  end
end

def save_data(data)
  File.write(DATA_FILE, JSON.pretty_generate(data))
end

# Home page
get '/' do
  @data = load_data
  @transactions = @data['transactions'].sort_by { |t| t['date'] }.reverse
  
  # Calculate totals
  @total_income = @transactions.select { |t| t['type'] == 'income' }.sum { |t| t['amount'] }
  @total_expenses = @transactions.select { |t| t['type'] == 'expense' }.sum { |t| t['amount'] }
  @balance = @total_income - @total_expenses
  
  # Group expenses by category
  @expenses_by_category = @transactions
    .select { |t| t['type'] == 'expense' }
    .group_by { |t| t['category'] }
    .transform_values { |transactions| transactions.sum { |t| t['amount'] } }
    .sort_by { |_, amount| -amount }
  
  # Get current month transactions
  current_month_start = Date.today.to_time.strftime('%Y-%m-01')
  @month_transactions = @transactions.select { |t| t['date'] >= current_month_start }
  @month_income = @month_transactions.select { |t| t['type'] == 'income' }.sum { |t| t['amount'] }
  @month_expenses = @month_transactions.select { |t| t['type'] == 'expense' }.sum { |t| t['amount'] }
  
  erb :index
end

# Add transaction
post '/transaction' do
  data = load_data
  
  transaction = {
    'id' => Time.now.to_i.to_s + rand(1000).to_s,
    'date' => params[:date],
    'type' => params[:type],
    'amount' => params[:amount].to_f,
    'category' => params[:category],
    'description' => params[:description]
  }
  
  data['transactions'] << transaction
  save_data(data)
  
  redirect '/'
end

# Delete transaction
post '/transaction/:id/delete' do
  data = load_data
  data['transactions'].reject! { |t| t['id'] == params[:id] }
  save_data(data)
  redirect '/'
end

# Set budget
post '/budget' do
  data = load_data
  data['budgets'][params[:category]] = params[:amount].to_f
  save_data(data)
  redirect '/'
end

__END__

@@layout
<!DOCTYPE html>
<html>
<head>
  <title>FineGems - Personal Finance Tracker</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: linear-gradient(135deg, #8B0000 0%, #DC143C 50%, #FF6347 100%);
      min-height: 100vh;
      padding: 20px;
    }
    
    .container {
      max-width: 1400px;
      margin: 0 auto;
    }
    
    .header {
      text-align: center;
      margin-bottom: 40px;
      animation: fadeIn 0.8s ease-in;
    }
    
    .header h1 {
      color: #FFF8DC;
      font-size: 3em;
      margin-bottom: 10px;
      text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
      letter-spacing: 2px;
    }
    
    .header .tagline {
      color: #FFE4B5;
      font-size: 1.2em;
      font-style: italic;
    }
    
    .gem-icon {
      display: inline-block;
      font-size: 1.5em;
      animation: sparkle 2s infinite;
    }
    
    @keyframes sparkle {
      0%, 100% { transform: rotate(0deg) scale(1); }
      50% { transform: rotate(20deg) scale(1.1); }
    }
    
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(-20px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    .summary {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 25px;
      margin-bottom: 40px;
    }
    
    .summary-card {
      background: linear-gradient(145deg, #FFF8DC 0%, #FAEBD7 100%);
      padding: 30px;
      border-radius: 20px;
      box-shadow: 0 8px 16px rgba(0,0,0,0.2);
      transition: transform 0.3s ease, box-shadow 0.3s ease;
      border: 2px solid #CD853F;
    }
    
    .summary-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 12px 24px rgba(0,0,0,0.3);
    }
    
    .summary-card h3 {
      color: #8B4513;
      font-size: 0.9em;
      margin-bottom: 15px;
      text-transform: uppercase;
      letter-spacing: 1px;
      font-weight: 600;
    }
    
    .summary-card .amount {
      font-size: 2.5em;
      font-weight: bold;
    }
    
    .summary-card .subtext {
      font-size: 0.9em;
      color: #A0522D;
      margin-top: 10px;
    }
    
    .income { color: #228B22; }
    .expense { color: #DC143C; }
    .balance { color: #FF8C00; }
    
    .panels {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 25px;
      margin-bottom: 40px;
    }
    
    .panel {
      background: linear-gradient(145deg, #FFF8DC 0%, #FAEBD7 100%);
      padding: 30px;
      border-radius: 20px;
      box-shadow: 0 8px 16px rgba(0,0,0,0.2);
      border: 2px solid #CD853F;
    }
    
    .panel h2 {
      margin-bottom: 25px;
      color: #8B0000;
      border-bottom: 3px solid #DC143C;
      padding-bottom: 15px;
      font-size: 1.5em;
    }
    
    form {
      display: flex;
      flex-direction: column;
      gap: 18px;
    }
    
    label {
      font-weight: 600;
      color: #8B4513;
      margin-bottom: 5px;
      display: block;
    }
    
    input, select, textarea {
      padding: 12px 15px;
      border: 2px solid #DEB887;
      border-radius: 10px;
      font-size: 1em;
      font-family: inherit;
      background: #FFFAF0;
      transition: border-color 0.3s ease;
    }
    
    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: #DC143C;
      box-shadow: 0 0 0 3px rgba(220, 20, 60, 0.1);
    }
    
    button {
      padding: 14px 24px;
      background: linear-gradient(135deg, #DC143C 0%, #8B0000 100%);
      color: #FFF8DC;
      border: none;
      border-radius: 10px;
      font-size: 1.1em;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s ease;
      box-shadow: 0 4px 8px rgba(0,0,0,0.2);
      text-transform: uppercase;
      letter-spacing: 1px;
    }
    
    button:hover {
      background: linear-gradient(135deg, #FF1493 0%, #DC143C 100%);
      transform: translateY(-2px);
      box-shadow: 0 6px 12px rgba(0,0,0,0.3);
    }
    
    button:active {
      transform: translateY(0);
    }
    
    .transactions-list {
      background: linear-gradient(145deg, #FFF8DC 0%, #FAEBD7 100%);
      padding: 30px;
      border-radius: 20px;
      box-shadow: 0 8px 16px rgba(0,0,0,0.2);
      border: 2px solid #CD853F;
    }
    
    .transaction-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 20px;
      border-bottom: 2px solid #F5DEB3;
      background: #FFFAF0;
      margin-bottom: 10px;
      border-radius: 10px;
      transition: background 0.3s ease;
    }
    
    .transaction-item:hover {
      background: #FFF5E1;
    }
    
    .transaction-item:last-child {
      margin-bottom: 0;
    }
    
    .transaction-info {
      flex: 1;
    }
    
    .transaction-desc {
      font-weight: 600;
      color: #8B4513;
      font-size: 1.1em;
      margin-bottom: 5px;
    }
    
    .transaction-date {
      color: #A0522D;
      font-size: 0.9em;
    }
    
    .transaction-category {
      display: inline-block;
      padding: 4px 12px;
      background: linear-gradient(135deg, #FFE4B5 0%, #F5DEB3 100%);
      border-radius: 20px;
      font-size: 0.85em;
      margin-left: 10px;
      font-weight: 500;
      color: #8B4513;
      border: 1px solid #DEB887;
    }
    
    .transaction-amount {
      font-size: 1.4em;
      font-weight: bold;
      margin-right: 20px;
    }
    
    .delete-btn {
      padding: 8px 18px;
      background: linear-gradient(135deg, #DC143C 0%, #8B0000 100%);
      font-size: 0.9em;
    }
    
    .delete-btn:hover {
      background: linear-gradient(135deg, #FF1493 0%, #DC143C 100%);
    }
    
    .category-breakdown {
      margin-top: 15px;
    }
    
    .category-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 15px;
      background: #FFFAF0;
      margin-bottom: 12px;
      border-radius: 10px;
      border: 2px solid #F5DEB3;
      transition: all 0.3s ease;
    }
    
    .category-item:hover {
      border-color: #DEB887;
      transform: translateX(5px);
    }
    
    .category-name {
      font-weight: 600;
      color: #8B4513;
    }
    
    .category-amount {
      font-weight: bold;
      color: #DC143C;
      font-size: 1.2em;
    }
    
    .empty-state {
      text-align: center;
      padding: 40px;
      color: #A0522D;
      font-style: italic;
    }
    
    .quick-categories {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      margin-top: 10px;
    }
    
    .quick-category-btn {
      padding: 8px 15px;
      background: linear-gradient(135deg, #FFE4B5 0%, #F5DEB3 100%);
      color: #8B4513;
      border: 2px solid #DEB887;
      border-radius: 20px;
      font-size: 0.9em;
      cursor: pointer;
      transition: all 0.3s ease;
      font-weight: 500;
    }
    
    .quick-category-btn:hover {
      background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
      transform: scale(1.05);
    }
    
    @media (max-width: 968px) {
      .panels {
        grid-template-columns: 1fr;
      }
      
      .header h1 {
        font-size: 2em;
      }
      
      .summary {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <%= yield %>
  
  <script>
    // Quick category selection
    function selectCategory(category) {
      document.querySelector('input[name="category"]').value = category;
    }
  </script>
</body>
</html>

@@index
<div class="container">
  <div class="header">
    <h1><span class="gem-icon">💎</span> FineGems <span class="gem-icon">💎</span></h1>
    <p class="tagline">Your Personal Finance Treasure Tracker</p>
  </div>
  
  <div class="summary">
    <div class="summary-card">
      <h3>💰 Total Income</h3>
      <div class="amount income">$<%= "%.2f" % @total_income %></div>
      <div class="subtext">This month: $<%= "%.2f" % @month_income %></div>
    </div>
    <div class="summary-card">
      <h3>💸 Total Expenses</h3>
      <div class="amount expense">$<%= "%.2f" % @total_expenses %></div>
      <div class="subtext">This month: $<%= "%.2f" % @month_expenses %></div>
    </div>
    <div class="summary-card">
      <h3>💎 Current Balance</h3>
      <div class="amount balance">$<%= "%.2f" % @balance %></div>
      <div class="subtext"><%= @balance >= 0 ? "You're doing great!" : "Time to review spending" %></div>
    </div>
  </div>
  
  <div class="panels">
    <div class="panel">
      <h2>✨ Add Transaction</h2>
      <form action="/transaction" method="post">
        <div>
          <label>📅 Date:</label>
          <input type="date" name="date" value="<%= Date.today %>" required>
        </div>
        
        <div>
          <label>🔀 Type:</label>
          <select name="type" required>
            <option value="expense">💸 Expense</option>
            <option value="income">💰 Income</option>
          </select>
        </div>
        
        <div>
          <label>💵 Amount:</label>
          <input type="number" name="amount" step="0.01" placeholder="0.00" required>
        </div>
        
        <div>
          <label>🏷️ Category:</label>
          <input type="text" name="category" placeholder="e.g., Groceries, Salary" required>
          <div class="quick-categories">
            <button type="button" class="quick-category-btn" onclick="selectCategory('Groceries')">🛒 Groceries</button>
            <button type="button" class="quick-category-btn" onclick="selectCategory('Dining')">🍽️ Dining</button>
            <button type="button" class="quick-category-btn" onclick="selectCategory('Transport')">🚗 Transport</button>
            <button type="button" class="quick-category-btn" onclick="selectCategory('Entertainment')">🎬 Fun</button>
            <button type="button" class="quick-category-btn" onclick="selectCategory('Salary')">💼 Salary</button>
          </div>
        </div>
        
        <div>
          <label>📝 Description:</label>
          <textarea name="description" rows="2" placeholder="Optional notes about this transaction"></textarea>
        </div>
        
        <button type="submit">💎 Add to FineGems</button>
      </form>
    </div>
    
    <div class="panel">
      <h2>📊 Expenses by Category</h2>
      <div class="category-breakdown">
        <% if @expenses_by_category.empty? %>
          <div class="empty-state">
            <p>No expenses tracked yet.<br>Start adding transactions to see your spending breakdown!</p>
          </div>
        <% else %>
          <% @expenses_by_category.each do |category, amount| %>
            <div class="category-item">
              <span class="category-name">🏷️ <%= category %></span>
              <span class="category-amount">$<%= "%.2f" % amount %></span>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
  </div>
  
  <div class="transactions-list">
    <h2>📜 Recent Transactions</h2>
    <% if @transactions.empty? %>
      <div class="empty-state">
        <p>✨ No transactions yet. Add your first gem above! ✨</p>
      </div>
    <% else %>
      <% @transactions.first(20).each do |transaction| %>
        <div class="transaction-item">
          <div class="transaction-info">
            <div class="transaction-desc">
              <%= transaction['description'].to_s.empty? ? transaction['category'] : transaction['description'] %>
              <span class="transaction-category"><%= transaction['category'] %></span>
            </div>
            <div class="transaction-date">📅 <%= Date.parse(transaction['date']).strftime('%B %d, %Y') %></div>
          </div>
          <div class="transaction-amount <%= transaction['type'] %>">
            <%= transaction['type'] == 'income' ? '+' : '-' %>$<%= "%.2f" % transaction['amount'] %>
          </div>
          <form action="/transaction/<%= transaction['id'] %>/delete" method="post" style="margin: 0;">
            <button type="submit" class="delete-btn">🗑️ Delete</button>
          </form>
        </div>
      <% end %>
    <% end %>
  </div>
</div>