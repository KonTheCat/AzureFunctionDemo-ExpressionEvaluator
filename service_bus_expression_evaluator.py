import logging
import azure.functions as func

bp_service_bus_expression_evaluator = func.Blueprint()

bp_service_bus_expression_evaluator.route(route= "service_bus_expression_evaluator")
@bp_service_bus_expression_evaluator.service_bus_queue_trigger(arg_name= "msg", queue_name= "questions", connection= "servicebus")
@bp_service_bus_expression_evaluator.service_bus_queue_output(arg_name= "msgout", queue_name= "answers", connection= "servicebus")
def service_bus_expression_evaluator(msg: func.ServiceBusMessage, msgout: func.Out[str]):
    logging.info('Python ServiceBus queue trigger processed message: %s',
                 msg.get_body().decode('utf-8'))
    
    expression = msg.get_body().decode('utf-8')
    result = eval(expression)
    output = f'{expression} = {result}'
    logging.info(f'Write to output: {output}')
    msgout.set(output)