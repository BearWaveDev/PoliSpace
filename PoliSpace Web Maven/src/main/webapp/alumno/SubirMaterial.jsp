<%@ include file="/includes/base.jspf" %>
<%
    String titulo = "Subir material";
%>
<%@ include file="/includes/top.jspf" %>
<p class="subtitle" style="margin:-16px 0 20px;">Comparte apuntes útiles con tu plantel. Formatos: PDF, Word, PowerPoint, Excel, JPG, PNG o ZIP (máximo 10 MB).</p>
<form class="form-card" action="<%= ctx %>/SubirMaterial" method="POST" enctype="multipart/form-data">
    <%= Util.csrfField(session) %>
    <div class="form-grid">
        <div class="campo"><label for="titulo">Título</label>
            <input type="text" id="titulo" name="titulo" minlength="3" maxlength="100" placeholder="Ej: Guía de ejercicios de Física" required></div>
        <div class="campo"><label for="categoria">Categoría</label>
            <select id="categoria" name="categoria">
                <option value="apunte">Apunte</option><option value="guia">Guía</option><option value="presentacion">Presentación</option>
                <option value="ejercicio">Ejercicio</option><option value="libro">Libro</option><option value="otro">Otro</option>
            </select></div>
        <div class="campo ancho"><label for="descripcion">Descripción (opcional)</label>
            <textarea id="descripcion" name="descripcion" maxlength="500" placeholder="¿De qué trata este material?"></textarea></div>
        <div class="campo ancho"><label for="archivo">Archivo</label>
            <input type="file" id="archivo" name="archivo" accept=".pdf,.doc,.docx,.ppt,.pptx,.xls,.xlsx,.jpg,.jpeg,.png,.zip" required></div>
    </div>
    <div class="form-acciones">
        <button class="btn-primary" type="submit">Publicar material</button>
        <a class="btn-sec" href="MaterialEstudio.jsp">Cancelar</a>
    </div>
</form>
<%@ include file="/includes/bottom.jspf" %>
