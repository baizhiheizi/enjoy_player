---
mcp-servers:
  web-search-prime:
    url: "https://open.bigmodel.cn/api/mcp/web_search_prime/mcp"
    headers: 
      Authorization: "Bearer ${{ secrets.ZAI_API_KEY }}"
    allowed: ["*"]
  zread:
    url: "https://open.bigmodel.cn/api/mcp/zread/mcp"
    headers:
      Authorization: "Bearer ${{ secrets.ZAI_API_KEY }}"
  web-reader:
    url: "https://open.bigmodel.cn/api/mcp/web_reader/mcp"
    headers: 
      Authorization: "Bearer ${{ secrets.ZAI_API_KEY }}"
    allowed: ["*"]
---
