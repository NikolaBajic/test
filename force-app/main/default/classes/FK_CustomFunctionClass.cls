public class FK_CustomFunctionClass implements FLX_KB.KanBanInterfaces.FunctionInterface {
    public Object executeFunction(String name, List<Object> parameters, Map<String, Object> context) {
        if (name == 'NUMBERFORMAT') {
            if (parameters.isEmpty() || parameters[0] == null) return '';
            
            Decimal result = (Decimal) parameters[0];
            return result.format();
        }
        return '';
    }
    
    public Object validateFunction(String name, List<Object> parameters) {
        return null;
    }
}