<%
String env = System.getenv("DEPLOY_ENV");
String color = "green".equals(env) ? "green" : "blue";
%>

<div style="background:<%=color%>;color:white;padding:10px">
  <%= env.toUpperCase() %> ENVIRONMENT
</div>
