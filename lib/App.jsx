import Meteor, { Mongo, withTracker } from '@meteorrn/core';
import { View, ScrollView, Text } from 'react-native';

Meteor.connect("wss://myapp.meteor.com/websocket");
const Todos = new Mongo.Collection("todos");
const MyAppContainer = withTracker(() => {
    
    const myTodoTasks = Todos.find({completed:false}).fetch();
    const handle = Meteor.subscribe("myTodos");
    
    return {
        myTodoTasks,
        loading:!handle.ready()
    };
   
    
    class MyApp extends React.Component {
        render() {
            const { loading, myTodoTasks } = this.props;
            
            if(loading) {
                return <View><Text>Loading your tasks...</Text></View>
            }
            
            return (
                <ScrollView>
                    {!myTodoTasks.length ?
                        <Text>You don't have any tasks</Text>
                    :
                        myTodoTasks.map(task => (
                            <Text>{task.text}</Text>
                        ))
                    }
                </ScrollView>
            );
        }
    }   
   
    
})(MyApp);


