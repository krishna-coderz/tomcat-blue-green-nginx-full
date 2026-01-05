<%
String env = System.getenv("DEPLOY_ENV");

// Default values (safety)
if (env == null || env.trim().isEmpty()) {
    env = "unknown";
}

String color;
switch (env.toLowerCase()) {
    case "green":
        color = "green";
        break;
    case "blue":
        color = "blue";
        break;
    default:
        color = "gray";
        break;
}
%>

<div style="background:<%= color %>; color:white; padding:10px; font-weight:bold;">
    <%= env.toUpperCase() %> ENVIRONMENT
</div>
