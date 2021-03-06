<%
/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file 
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
%>
<%@ page import = "javax.servlet.http.*" %>
<%@ page import = "java.sql.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.util.Calendar" %>
<%@ page import = "java.util.Date" %>
<%@ page import = "java.text.SimpleDateFormat" %>
<%@ page import = "java.util.*" %>
<%@ page import = "org.json.*" %>
<%@ page import = "org.apache.hadoop.chukwa.hicc.ClusterConfig" %>
<%@ page import = "org.apache.hadoop.chukwa.hicc.TimeHandler" %>
<%@ page import = "org.apache.hadoop.chukwa.database.DatabaseConfig" %>
<%@ page import = "org.apache.hadoop.chukwa.util.XssFilter"  %>
<% XssFilter xf = new XssFilter(request);
   String boxId = xf.getParameter("boxId");
   response.setHeader("boxId", xf.getParameter("boxId"));
%>
<div class="panel">
<h2>Hosts</h2>
<fieldset>
<div class="row">
<select id="<%= boxId %>group_items" name="<%= boxId %>group_items" MULTIPLE size=10 class="formSelect" style="width:200px;">
<%
    JSONArray machineNames = null;
    if(session.getAttribute("cache.machine_names")!=null) {
        machineNames = new JSONArray(session.getAttribute("cache.machine_names").toString());
    }
    String cluster=xf.getParameter("cluster");
    if(cluster!=null && !cluster.equals("null")) {
        session.setAttribute("cluster",cluster);
    } else {
        cluster = (String) session.getAttribute("cluster");
        if(cluster==null || cluster.equals("null")) {
            cluster="demo";
            session.setAttribute("cluster",cluster);
        }
    }
    ClusterConfig cc = new ClusterConfig();
    String jdbc = cc.getURL(cluster);
    TimeHandler time = new TimeHandler(request,(String)session.getAttribute("time_zone"));
    String startS = time.getStartTimeText();
    String endS = time.getEndTimeText();
    String timefield = "timestamp";
    String dateclause = timefield+" >= '"+startS+"' and "+timefield+" <= '"+endS+"'";
    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;
    String query = "";
    try {
        HashMap<String, String> hosts = new HashMap<String, String>();
        try {
            String[] selected_hosts = ((String)session.getAttribute("hosts")).split(",");
            for(String name: selected_hosts) {
                hosts.put(name,name);
            }
        } catch (NullPointerException e) {
    }
           conn = org.apache.hadoop.chukwa.util.DriverManagerUtil.getConnection(jdbc);
           stmt = conn.createStatement();
           String jobId = (String)session.getAttribute("JobID");
           if(jobId!=null && !jobId.equals("null") && !jobId.equals("")) {
               query = "select DISTINCT Machine from HodMachine where HodID='"+jobId+"' order by Machine;";
           } else if(machineNames==null) {
               long start = time.getStartTime();
               long end = time.getEndTime(); 
               String table = "system_metrics";
               DatabaseConfig dbc = new DatabaseConfig();
               String[] tables = dbc.findTableNameForCharts(table, start, end);
               table=tables[0];
               query="select DISTINCT host from "+table+" order by host";
           }
           // or alternatively, if you don't know ahead of time that
           // the query will be a SELECT...
           if(!query.equals("")) {
               if (stmt.execute(query)) {
                   int i=0;
                   rs = stmt.getResultSet();
                   rs.last();
                   int size = rs.getRow();
                   machineNames = new JSONArray();
                   rs.beforeFirst();
                   while (rs.next()) {
                       String machine = rs.getString(1);
                       machineNames.put(machine);
                       if(hosts.containsKey(machine)) {
                           out.println("<option selected>"+machine+"</option>");
                       } else {
                           out.println("<option>"+machine+"</option>");
                       }
                       i++;
                   }
                   if(jobId==null || jobId.equals("null") || jobId.equals("")) {
                       session.setAttribute("cache.machine_names",machineNames.toString());
                   }
               }
           } else {
                   for(int j=0;j<machineNames.length();j++) {
                       String machine = machineNames.get(j).toString();
                       if(hosts.containsKey(machine)) {
                           out.println("<option selected>"+machine+"</option>");
                       } else {
                           out.println("<option>"+machine+"</option>");
                       }
                   }
           }
           // Now do something with the ResultSet ....
       } catch (SQLException ex) {
           // handle any errors
           // FIXME: should we use Log4j here?
           System.out.println("SQLException on query " + query +" " + ex.getMessage());
           System.out.println("SQLState: " + ex.getSQLState());
           System.out.println("VendorError: " + ex.getErrorCode());
       } finally {
           // it is a good idea to release
           // resources in a finally{} block
           // in reverse-order of their creation
           // if they are no-longer needed
           if (rs != null) {
               try {
                   rs.close();
               } catch (SQLException sqlEx) {
                   // ignore
               }
               rs = null;
           }
           if (stmt != null) {
               try {
                   stmt.close();
               } catch (SQLException sqlEx) {
                   // ignore
               }
               stmt = null;
           }
           if (conn != null) {
               try {
                   conn.close();
               } catch (SQLException sqlEx) {
                   // ignore
               }
               conn = null;
           }
       }
%>
</select></div>
<div class="row">
<input type="button" onClick="save_host('<%= boxId %>');" name="Apply" value="Apply" class="formButton">
</div>
</fieldset>
</div>
